import type { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { ZodError } from 'zod';
import { errorResponse, AppError, type ApiErrorDetail } from '../utils/response.ts';
import { config } from '../config/index.ts';

/**
 * Maps Zod issues to standardized ApiErrorDetail objects
 */
function formatZodIssues(error: ZodError): ApiErrorDetail[] {
  return error.issues.map((issue) => ({
    field: issue.path.join('.'),
    message: issue.message,
    code: issue.code,
  }));
}

/**
 * Check if the error is a PostgreSQL database error
 */
interface PgDatabaseError extends Error {
  code?: string;
  detail?: string;
  table?: string;
  constraint?: string;
  column?: string;
}

function handlePgError(err: PgDatabaseError, c: Context) {
  switch (err.code) {
    case '23505': // unique_violation
      return errorResponse(
        c,
        409,
        'UNIQUE_VIOLATION',
        'A record with this information already exists',
        err.detail ? { detail: err.detail, constraint: err.constraint } : undefined
      );

    case '23503': // foreign_key_violation
      return errorResponse(
        c,
        400,
        'FOREIGN_KEY_VIOLATION',
        'Referenced entity does not exist or cannot be modified',
        err.detail ? { detail: err.detail, table: err.table } : undefined
      );

    case '23502': // not_null_violation
      return errorResponse(
        c,
        400,
        'NOT_NULL_VIOLATION',
        `Missing required column: ${err.column || 'unknown'}`,
        { column: err.column }
      );

    case '22P02': // invalid_text_representation (e.g. invalid UUID format)
      return errorResponse(
        c,
        400,
        'INVALID_INPUT_SYNTAX',
        'Invalid input format or identifier type provided'
      );

    case '40001': // serialization_failure
      return errorResponse(
        c,
        409,
        'TRANSACTION_CONFLICT',
        'Database transaction conflict, please retry the operation'
      );

    case '57014': // query_canceled / timeout
      return errorResponse(
        c,
        504,
        'DATABASE_TIMEOUT',
        'Database query timed out'
      );

    default:
      return null;
  }
}

/**
 * Global Error Handler for Hono
 */
export function errorHandler(err: Error, c: Context) {
  // 1. Custom Application Domain Errors
  if (err instanceof AppError || (err && typeof (err as any).statusCode === 'number' && typeof (err as any).errorCode === 'string')) {
    const appErr = err as AppError;
    if (appErr.isOperational === false) {
      console.error(`💥 Non-operational AppError [${appErr.errorCode || appErr.code}]:`, err);
    }
    return errorResponse(
      c,
      (appErr.statusCode || 400) as any,
      appErr.errorCode || appErr.code || 'APP_ERROR',
      appErr.message,
      appErr.details as any
    );
  }

  // 2. Zod Validation Errors
  if (err instanceof ZodError) {
    const details = formatZodIssues(err);
    return errorResponse(
      c,
      422,
      'VALIDATION_ERROR',
      'Request validation failed',
      details
    );
  }

  // 3. Hono Built-in HTTP Exceptions
  if (err instanceof HTTPException) {
    return errorResponse(
      c,
      err.status,
      `HTTP_${err.status}`,
      err.message
    );
  }

  // 4. PostgreSQL Errors
  const pgErr = err as PgDatabaseError;
  if (pgErr.code && typeof pgErr.code === 'string' && /^[0-9A-Z]{5}$/.test(pgErr.code)) {
    const pgHandled = handlePgError(pgErr, c);
    if (pgHandled) {
      return pgHandled;
    }
  }

  // 5. JWT Errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError' || err.name === 'NotBeforeError') {
    return errorResponse(
      c,
      401,
      'AUTH_TOKEN_INVALID',
      err.message || 'Invalid or expired token'
    );
  }

  // 6. Unhandled Internal Server Errors (500)
  console.error('💥 Unhandled Exception:', err);

  const isDev = config.NODE_ENV === 'development' || config.NODE_ENV === 'test' || config.isDev;
  const details = isDev
    ? {
        stack: err.stack,
        name: err.name,
      }
    : undefined;

  return errorResponse(
    c,
    500,
    'INTERNAL_SERVER_ERROR',
    'An unexpected error occurred on the server',
    details
  );
}

/**
 * 404 Not Found Handler for unmatched routes
 */
export function notFoundHandler(c: Context) {
  return errorResponse(
    c,
    404,
    'ROUTE_NOT_FOUND',
    `Cannot ${c.req.method} ${c.req.path}`
  );
}
