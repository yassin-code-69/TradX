export interface CreateDepositInput {
  paymentMethodId?: number | string;
  paymentMethodCode?: string;
  method?: string; // Fallback alias
  amountMinor: number | string | bigint;
  senderAccount: string;
  providerTransactionId?: string;
  trxId?: string; // Fallback alias
  proofAssetId?: number | string;
}

export interface DepositItem {
  id: string;
  publicId: string;
  userId: string;
  username: string;
  paymentMethodId: string;
  paymentMethodCode: string;
  paymentMethodName: string;
  amountMinor: string;
  formattedAmount: string;
  senderAccount: string;
  providerTransactionId: string;
  proofAssetId: string | null;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';
  reviewedBy: string | null;
  reviewedAt: string | null;
  rejectReason: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ApproveDepositInput {
  note?: string;
}

export interface RejectDepositInput {
  reason: string;
}

export interface DepositQueryFilters {
  status?: string;
  paymentMethodId?: string | number;
  fromDate?: string;
  toDate?: string;
  page?: number;
  limit?: number;
}
