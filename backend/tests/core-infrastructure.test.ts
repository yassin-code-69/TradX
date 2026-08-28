import { describe, expect, it } from 'bun:test';
import { Hono } from 'hono';
import jwt from 'jsonwebtoken';
import { config } from '../src/config/index.ts';
import {
  successResponse,
  errorResponse,
  createdResponse,
  noContentResponse,
  paginatedResponse,
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  ValidationError,
  InternalServerError,
} from '../src/utils/response.ts';
import { requireAuth, optionalAuth } from '../src/middleware/auth.ts';
import { requireRole, requirePermission, requireAllRoles, requireAllPermissions } from '../src/middleware/rbac.ts';
import { errorHandler, notFoundHandler } from '../src/middleware/errorHandler.ts';
import { dbPool, withTransaction, query, checkDbHealth } from '../src/db/client.ts';

describe('Core Infrastructure Test Suite', () => {
  describe('1. Configuration Layer (config/index.ts)', () => {
    it('should properly load and expose environment configurations', () => {
      expect(config.PORT).toBeDefined();
      expect(typeof config.PORT).toBe('number');
      expect(config.NODE_ENV).toBeDefined();
      expect(config.SUPABASE_URL).toBeDefined();
      expect(config.SUPABASE_ANON_KEY).toBeDefined();
      expect(config.SUPABASE_SERVICE_ROLE_KEY).toBeDefined();
      expect(config.DATABASE_URL).toBeDefined();
      expect(config.DEFAULT_CURRENCY).toBe('BDT');
    });

    it('should expose camelCase compatibility aliases', () => {
      expect(config.port).toBe(config.PORT);
      expect(config.nodeEnv).toBe(config.NODE_ENV);
      expect(config.databaseUrl).toBe(config.DATABASE_URL);
      expect(config.jwtSecret).toBe(config.SUPABASE_JWT_SECRET);
    });
  });

  describe('2. Response and Error Utilities (utils/response.ts)', () => {
    const testApp = new Hono();

    testApp.get('/test/success', (c) => successResponse(c, { user: 'Alice' }, { count: 1 }));
    testApp.post('/test/created', (c) => createdResponse(c, { id: 'created-1' }));
    testApp.delete('/test/no-content', (c) => noContentResponse(c));
    testApp.get('/test/paginated', (c) =>
      paginatedResponse(c, [{ id: 1 }, { id: 2 }], { total: 10, page: 1, limit: 2 })
    );
    testApp.get('/test/error', (c) =>
      errorResponse(c, 400, 'CUSTOM_BAD_REQUEST', 'Something is wrong', [{ field: 'email', message: 'invalid' }])
    );

    it('successResponse returns 200 with standard envelope', async () => {
      const res = await testApp.request('/test/success');
      expect(res.status).toBe(200);
      const json = (await res.json()) as any;
      expect(json.success).toBe(true);
      expect(json.data.user).toBe('Alice');
      expect(json.meta.count).toBe(1);
      expect(json.timestamp).toBeDefined();
    });

    it('createdResponse returns 201 Created', async () => {
      const res = await testApp.request('/test/created', { method: 'POST' });
      expect(res.status).toBe(201);
      const json = (await res.json()) as any;
      expect(json.success).toBe(true);
      expect(json.data.id).toBe('created-1');
    });

    it('noContentResponse returns 204 No Content', async () => {
      const res = await testApp.request('/test/no-content', { method: 'DELETE' });
      expect(res.status).toBe(204);
    });

    it('paginatedResponse returns structured pagination metadata', async () => {
      const res = await testApp.request('/test/paginated');
      expect(res.status).toBe(200);
      const json = (await res.json()) as any;
      expect(json.success).toBe(true);
      expect(json.data.length).toBe(2);
      expect(json.meta.pagination).toEqual({
        total: 10,
        page: 1,
        limit: 2,
        offset: undefined,
        totalPages: 5,
        hasNextPage: true,
        hasPrevPage: false,
      });
    });

    it('errorResponse returns structured error envelope', async () => {
      const res = await testApp.request('/test/error');
      expect(res.status).toBe(400);
      const json = (await res.json()) as any;
      expect(json.success).toBe(false);
      expect(json.error.code).toBe('CUSTOM_BAD_REQUEST');
      expect(json.error.message).toBe('Something is wrong');
      expect(json.error.details).toEqual([{ field: 'email', message: 'invalid' }]);
      expect(json.timestamp).toBeDefined();
    });

    it('should correctly instantiate domain errors', () => {
      const appErr = new AppError('General error', 400, 'GENERAL_ERROR');
      expect(appErr.statusCode).toBe(400);
      expect(appErr.errorCode).toBe('GENERAL_ERROR');

      const unauthErr = new UnauthorizedError('Unauthorized');
      expect(unauthErr.statusCode).toBe(401);

      const forbErr = new ForbiddenError('Forbidden');
      expect(forbErr.statusCode).toBe(403);

      const notFoundErr = new NotFoundError('Not found');
      expect(notFoundErr.statusCode).toBe(404);

      const badReqErr = new BadRequestError('Bad input');
      expect(badReqErr.statusCode).toBe(400);

      const confErr = new ConflictError('Conflict');
      expect(confErr.statusCode).toBe(409);

      const valErr = new ValidationError('Validation error', [{ field: 'name', message: 'required' }]);
      expect(valErr.statusCode).toBe(422);

      const srvErr = new InternalServerError('Server error');
      expect(srvErr.statusCode).toBe(500);
      expect(srvErr.isOperational).toBe(false);
    });
  });

  describe('3. Auth and RBAC Middleware (middleware/auth.ts, middleware/rbac.ts)', () => {
    const testSecret = config.SUPABASE_JWT_SECRET || config.jwtSecret || 'test-secret';

    const testApp = new Hono();
    testApp.onError(errorHandler);

    testApp.get('/protected', requireAuth, (c) => {
      const user = c.get('user');
      return successResponse(c, { user });
    });

    testApp.get('/admin-only', requireAuth, requireRole('ADMIN'), (c) => {
      return successResponse(c, { access: 'admin-granted' });
    });

    testApp.get('/super-admin-only', requireAuth, requireRole('SUPER_ADMIN'), (c) => {
      return successResponse(c, { access: 'super-admin-granted' });
    });

    testApp.get('/draw-permission', requireAuth, requirePermission('draw.execute'), (c) => {
      return successResponse(c, { access: 'draw-permission-granted' });
    });

    testApp.get('/optional', optionalAuth, (c) => {
      const user = c.get('user');
      return successResponse(c, { authenticated: Boolean(user) });
    });

    it('rejects unauthenticated request with 401', async () => {
      const res = await testApp.request('/protected');
      expect(res.status).toBe(401);
      const json = (await res.json()) as any;
      expect(json.success).toBe(false);
      expect(json.error.code).toBe('UNAUTHORIZED');
    });

    it('authenticates user with valid JWT token', async () => {
      const token = jwt.sign(
        {
          sub: 'f87a32c7-062e-4b68-809a-6cfc6eb0d195',
          email: 'trader@tradex.com',
          role: 'USER',
        },
        testSecret
      );

      const res = await testApp.request('/protected', {
        headers: { Authorization: `Bearer ${token}` },
      });

      expect(res.status).toBe(200);
      const json = (await res.json()) as any;
      expect(json.success).toBe(true);
      expect(json.data.user.id).toBe('f87a32c7-062e-4b68-809a-6cfc6eb0d195');
    });

    it('allows optionalAuth without token', async () => {
      const res = await testApp.request('/optional');
      expect(res.status).toBe(200);
      const json = (await res.json()) as any;
      expect(json.data.authenticated).toBe(false);
    });

    it('allows optionalAuth with token', async () => {
      const token = jwt.sign(
        {
          sub: '123e4567-e89b-12d3-a456-426614174000',
          email: 'optional@tradex.com',
        },
        testSecret
      );

      const res = await testApp.request('/optional', {
        headers: { Authorization: `Bearer ${token}` },
      });

      expect(res.status).toBe(200);
      const json = (await res.json()) as any;
      expect(json.data.authenticated).toBe(true);
    });

    it('RBAC forbids regular USER from accessing /admin-only', async () => {
      const userToken = jwt.sign(
        {
          sub: '123e4567-e89b-12d3-a456-426614174001',
          email: 'user@tradex.com',
        },
        testSecret
      );

      const res = await testApp.request('/admin-only', {
        headers: { Authorization: `Bearer ${userToken}` },
      });

      expect(res.status).toBe(403);
      const json = (await res.json()) as any;
      expect(json.error.code).toBe('FORBIDDEN_ROLE');
    });
  });

  describe('4. Error Handler Middleware (middleware/errorHandler.ts)', () => {
    const errorApp = new Hono();
    errorApp.onError(errorHandler);
    errorApp.notFound(notFoundHandler);

    errorApp.get('/throw-bad-request', () => {
      throw new BadRequestError('Invalid input provided', 'CUSTOM_BAD_REQUEST', { field: 'amount' });
    });

    errorApp.get('/throw-unhandled', () => {
      throw new Error('Unexpected crash simulation');
    });

    it('catches AppError and formats JSON response', async () => {
      const res = await errorApp.request('/throw-bad-request');
      expect(res.status).toBe(400);
      const json = (await res.json()) as any;
      expect(json.success).toBe(false);
      expect(json.error.code).toBe('CUSTOM_BAD_REQUEST');
      expect(json.error.message).toBe('Invalid input provided');
      expect(json.error.details.field).toBe('amount');
    });

    it('catches unhandled errors and returns 500 INTERNAL_SERVER_ERROR', async () => {
      const res = await errorApp.request('/throw-unhandled');
      expect(res.status).toBe(500);
      const json = (await res.json()) as any;
      expect(json.success).toBe(false);
      expect(json.error.code).toBe('INTERNAL_SERVER_ERROR');
    });

    it('notFoundHandler returns 404 for unknown endpoints', async () => {
      const res = await errorApp.request('/non-existent-endpoint');
      expect(res.status).toBe(404);
      const json = (await res.json()) as any;
      expect(json.success).toBe(false);
      expect(json.error.code).toBe('ROUTE_NOT_FOUND');
    });
  });

  describe('5. Database Client & Helpers (db/client.ts)', () => {
    it('dbPool and functions should be defined', () => {
      expect(dbPool).toBeDefined();
      expect(typeof query).toBe('function');
      expect(typeof withTransaction).toBe('function');
      expect(typeof checkDbHealth).toBe('function');
    });
  });
});
