export interface SendTransferInput {
  recipient: string; // Username or phone number
  amountMinor: number | string | bigint;
  note?: string;
  idempotencyKey?: string;
}

export interface TransferItem {
  id: string;
  publicId: string;
  senderUserId: string;
  senderUsername: string;
  receiverUserId: string;
  receiverUsername: string;
  amountMinor: string;
  feeMinor: string;
  netAmountMinor: string;
  status: string;
  note: string | null;
  direction?: 'SENT' | 'RECEIVED';
  formattedAmount: string;
  formattedFee: string;
  createdAt: string;
  completedAt: string | null;
}

export interface TransferQueryFilters {
  direction?: 'SENT' | 'RECEIVED' | 'ALL';
  status?: string;
  fromDate?: string;
  toDate?: string;
  page?: number;
  limit?: number;
}
