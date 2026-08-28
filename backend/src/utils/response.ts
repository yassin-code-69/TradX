import type { Context } from 'hono';
import type { StatusCode } from 'hono/utils/http-status';
import {
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  ValidationError,
  InternalServerError,
  InsufficientBalanceError,
  type ErrorCode,
} from './errors.ts';

export * from './errors.ts';

export interface PaginationMeta {
  total: number;
  page?: number;
  limit?: number;
  offset?: number;
  totalPages?: number;
  hasNextPage?: boolean;
  hasPrevPage?: boolean;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data: T | null;
  meta?: Record<string, any>;
  error?: {
    code: string;
    message: string;
    details?: any;
  } | null;
  timestamp?: string;
}

export interface ApiErrorDetail {
  field?: string;
  message: string;
  code?: string;
  [key: string]: any;
}

export interface ApiErrorResponse {
  success: false;
  data: null;
  error: {
    code: string;
    message: string;
    details?: ApiErrorDetail[] | Record<string, any>;
  };
  timestamp: string;
}

/**
 * Standard HTTP success response helper
 */
export function successResponse<T>(
  c: Context,
  data: T,
  meta?: Record<string, any>,
  status: StatusCode = 200
) {
  const payload: ApiResponse<T> = {
    success: true,
    data,
    ...(meta ? { meta } : {}),
    error: null,
    timestamp: new Date().toISOString(),
  };

  return c.json(payload, status as any);
}

/**
 * Standard HTTP created response helper (201 Created)
 */
export function createdResponse<T>(
  c: Context,
  data: T,
  meta?: Record<string, any>
) {
  return successResponse(c, data, meta, 201);
}

/**
 * Standard HTTP no-content response helper (204 No Content)
 */
export function noContentResponse(c: Context) {
  return c.body(null, 204);
}

/**
 * Standard paginated response helper
 */
export function paginatedResponse<T>(
  c: Context,
  data: T[],
  pagination: { total: number; page?: number; limit?: number; offset?: number },
  extraMeta?: Record<string, any>
) {
  const total = pagination.total;
  const limit = pagination.limit ?? 20;
  const page = pagination.page ?? (pagination.offset !== undefined ? Math.floor(pagination.offset / limit) + 1 : 1);
  const totalPages = Math.ceil(total / Math.max(limit, 1));

  const paginationMeta: PaginationMeta = {
    total,
    page,
    limit,
    offset: pagination.offset,
    totalPages,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };

  return successResponse(
    c,
    data,
    {
      pagination: paginationMeta,
      ...(extraMeta || {}),
    },
    200
  );
}

/**
 * Standard HTTP error response helper
 */
export function errorResponse(
  c: Context,
  status: StatusCode = 500,
  code: string = 'INTERNAL_SERVER_ERROR',
  message: string = 'An unexpected error occurred',
  details?: ApiErrorDetail[] | Record<string, any>
) {
  const payload: ApiErrorResponse = {
    success: false,
    data: null,
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
    timestamp: new Date().toISOString(),
  };

  return c.json(payload, status as any);
}

/**
 * Backward compatibility aliases
 */
export const sendSuccess = <T>(
  c: Context,
  data: T,
  meta?: Record<string, any>,
  status: StatusCode = 200
) => successResponse(c, data, meta, status);

export const sendError = (
  c: Context,
  code: string,
  message: string,
  status: StatusCode = 400,
  details?: any
) => errorResponse(c, status, code, message, details);
