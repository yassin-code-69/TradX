export interface CreateWithdrawalInput {
  paymentMethodId?: number | string;
  paymentMethodCode?: string;
  receiverAccount: string;
  amountMinor: number | string | bigint;
  idempotencyKey?: string;
}

export interface WithdrawalItem {
  id: string;
  publicId: string;
  userId: string;
  username: string;
  paymentMethodId: string;
  paymentMethodCode: string;
  paymentMethodName: string;
  receiverAccount: string;
  amountMinor: string;
  feeMinor: string;
  netAmountMinor: string;
  formattedAmount: string;
  formattedFee: string;
  formattedNetAmount: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';
  reviewedBy: string | null;
  reviewedAt: string | null;
  completedAt: string | null;
  rejectReason: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ApproveWithdrawalInput {
  transactionReference?: string;
  note?: string;
}

export interface RejectWithdrawalInput {
  reason: string;
}

export interface WithdrawalQueryFilters {
  status?: string;
  paymentMethodId?: string | number;
  fromDate?: string;
  toDate?: string;
  page?: number;
  limit?: number;
}
