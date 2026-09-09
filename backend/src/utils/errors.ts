export type ErrorCode =
  | 'UNAUTHORIZED'
  | 'AUTH_REQUIRED'
  | 'AUTH_TOKEN_MISSING'
  | 'AUTH_TOKEN_INVALID'
  | 'FORBIDDEN'
  | 'FORBIDDEN_ROLE'
  | 'FORBIDDEN_PERMISSION'
  | 'NOT_FOUND'
  | 'BAD_REQUEST'
  | 'VALIDATION_ERROR'
  | 'USER_NOT_FOUND'
  | 'USER_BLOCKED'
  | 'USER_SUSPENDED'
  | 'ACCOUNT_SUSPENDED'
  | 'ACCOUNT_BLOCKED'
  | 'ACCOUNT_INACTIVE'
  | 'INSUFFICIENT_BALANCE'
  | 'RECIPIENT_NOT_FOUND'
  | 'SELF_TRANSFER_PROHIBITED'
  | 'TRANSFER_LIMIT_EXCEEDED'
  | 'PAYMENT_METHOD_NOT_FOUND'
  | 'PAYMENT_METHOD_DISABLED'
  | 'DEPOSIT_AMOUNT_OUT_OF_RANGE'
  | 'WITHDRAWAL_AMOUNT_OUT_OF_RANGE'
  | 'DEPOSIT_ALREADY_PROCESSED'
  | 'WITHDRAWAL_ALREADY_PROCESSED'
  | 'DUPLICATE_TRANSACTION_ID'
  | 'DUPLICATE_REQUEST'
  | 'CONFLICT'
  | 'UNIQUE_VIOLATION'
  | 'FOREIGN_KEY_VIOLATION'
  | 'NOT_NULL_VIOLATION'
  | 'INVALID_STATE_TRANSITION'
  | 'LEDGER_IMBALANCE'
  | 'RATE_LIMIT_EXCEEDED'
  | 'INTERNAL_SERVER_ERROR';

export class AppError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly errorCode: string;
  public readonly details?: unknown;
  public readonly isOperational: boolean;

  constructor(
    codeOrMessage: string,
    messageOrStatusCode: string | number = 'An error occurred',
    statusCodeOrCode: number | string = 400,
    details?: unknown,
    isOperational: boolean = true
  ) {
    let msg: string;
    let codeStr: string;
    let statusNum: number;

    if (typeof messageOrStatusCode === 'number') {
      // Called as: new AppError(message, statusCode, errorCode, details, isOperational)
      msg = codeOrMessage;
      statusNum = messageOrStatusCode;
      codeStr = typeof statusCodeOrCode === 'string' ? statusCodeOrCode : 'APP_ERROR';
    } else {
      // Called as: new AppError(code, message, statusCode, details, isOperational)
      codeStr = codeOrMessage;
      msg = messageOrStatusCode;
      statusNum = typeof statusCodeOrCode === 'number' ? statusCodeOrCode : 400;
    }

    super(msg);
    this.name = this.constructor.name;
    this.code = codeStr;
    this.errorCode = codeStr;
    this.statusCode = statusNum;
    this.details = details;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Authentication required', code: string = 'UNAUTHORIZED', details?: unknown) {
    super(code, message, 401, details);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Access forbidden', code: string = 'FORBIDDEN', details?: unknown) {
    super(code, message, 403, details);
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Resource not found', code: string = 'NOT_FOUND', details?: unknown) {
    super(code, message, 404, details);
  }
}

export class BadRequestError extends AppError {
  constructor(message: string = 'Bad request', code: string = 'BAD_REQUEST', details?: unknown) {
    super(code, message, 400, details);
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Resource conflict', code: string = 'CONFLICT', details?: unknown) {
    super(code, message, 409, details);
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed', details?: unknown) {
    super('VALIDATION_ERROR', message, 422, details);
  }
}

export class InternalServerError extends AppError {
  constructor(message: string = 'Internal server error', code: string = 'INTERNAL_SERVER_ERROR', details?: unknown) {
    super(code, message, 500, details, false);
  }
}

export class InsufficientBalanceError extends AppError {
  constructor(message: string = 'Insufficient available balance', details?: unknown) {
    super('INSUFFICIENT_BALANCE', message, 400, details);
  }
}

export class TooManyRequestsError extends AppError {
  constructor(message: string = 'Too many requests, please try again later', details?: unknown) {
    super('RATE_LIMIT_EXCEEDED', message, 429, details);
  }
}

