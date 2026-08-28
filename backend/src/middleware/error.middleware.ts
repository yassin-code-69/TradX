import type { Context } from 'hono';
import { ZodError } from 'zod';
import { AppError } from '../utils/errors.ts';
import { sendError } from '../utils/response.ts';

export function errorHandler(err: Error, c: Context) {
  console.error('Unhandled API Error:', err);

  if (err instanceof AppError) {
    return sendError(c, err.code, err.message, err.statusCode as any, err.details);
  }

  if (err instanceof ZodError) {
    const formattedErrors = err.issues.map((issue) => ({
      field: issue.path.join('.'),
      message: issue.message,
    }));
    return sendError(
      c,
      'VALIDATION_ERROR',
      'Validation failed for request parameters',
      400,
      formattedErrors
    );
  }

  return sendError(
    c,
    'INTERNAL_SERVER_ERROR',
    'An unexpected internal server error occurred',
    500
  );
}

export function notFoundHandler(c: Context) {
  return sendError(c, 'NOT_FOUND', `Route ${c.req.method} ${c.req.path} not found`, 404);
}
