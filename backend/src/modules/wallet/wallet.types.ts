export interface WalletBalance {
  availableBalanceMinor: string;
  lockedBalanceMinor: string;
  totalBalanceMinor: string;
  currency: string;
  formatted: {
    available: string;
    locked: string;
    total: string;
  };
}

export type LedgerTransactionType =
  | 'DEPOSIT'
  | 'WITHDRAWAL'
  | 'WITHDRAWAL_LOCK'
  | 'WITHDRAWAL_REJECT'
  | 'USER_TRANSFER'
  | 'TRANSFER_FEE'
  | 'TICKET_PURCHASE'
  | 'WINNING'
  | 'REFUND'
  | 'BONUS'
  | 'COMMISSION'
  | 'ADMIN_ADJUSTMENT'
  | 'REVERSAL';

export interface LedgerEntryItem {
  id: string;
  transactionId: string;
  accountId: string;
  accountType: string;
  ownerType: string;
  ownerId: string;
  amountMinor: string;
  createdAt: string;
}

export interface WalletTransactionItem {
  id: string;
  publicId: string;
  transactionType: LedgerTransactionType;
  amountMinor: string;
  netChangeMinor: string; // Positive for user credit, negative for user debit
  currency: string;
  referenceType: string | null;
  referenceId: string | null;
  status: string;
  metadata: Record<string, unknown>;
  createdAt: string;
  formattedAmount: string;
}

export interface TransactionHistoryQuery {
  type?: string;
  fromDate?: string;
  toDate?: string;
  page?: number;
  limit?: number;
}

export interface AdminAdjustBalanceInput {
  userId: string;
  amountMinor: number | string | bigint;
  type: 'CREDIT' | 'DEBIT';
  reason: string;
  note?: string;
}
