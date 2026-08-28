export type UserStatus = "ACTIVE" | "SUSPENDED" | "BLOCKED";
export type UserRole =
  | "USER"
  | "AGENT"
  | "ADMIN"
  | "FINANCE_ADMIN"
  | "SUPER_ADMIN";
export type KYCStatus = "VERIFIED" | "PENDING" | "REJECTED" | "NOT_SUBMITTED";

export interface UserItem {
  id: string;
  publicId: string;
  username: string;
  fullName: string;
  phone: string;
  email: string;
  avatarUrl?: string;
  status: UserStatus;
  role: UserRole;
  kycStatus: KYCStatus;
  availableBalanceMinor: number;
  lockedBalanceMinor: number;
  totalTicketsBought: number;
  totalWonMinor: number;
  totalDepositsMinor: number;
  totalWithdrawalsMinor: number;
  createdAt: string;
  updatedAt: string;
}

export type DepositStatus = "PENDING" | "APPROVED" | "REJECTED";
export type PaymentMethod = "bKash" | "Nagad" | "Rocket" | "Bank Transfer";

export interface DepositItem {
  id: string;
  publicId: string;
  userId: string;
  username: string;
  userFullName: string;
  paymentMethod: PaymentMethod;
  senderAccount: string;
  providerTransactionId: string;
  amountMinor: number;
  formattedAmount: string;
  proofImageUrl?: string;
  status: DepositStatus;
  submittedAt: string;
  reviewedAt?: string | null;
  reviewedBy?: string | null;
  rejectReason?: string | null;
  adminNote?: string | null;
}

export type WithdrawalStatus = "PENDING" | "APPROVED" | "REJECTED";

export interface WithdrawalItem {
  id: string;
  publicId: string;
  userId: string;
  username: string;
  userFullName: string;
  paymentMethod: PaymentMethod;
  receiverAccount: string;
  amountMinor: number;
  feeMinor: number;
  netAmountMinor: number;
  formattedAmount: string;
  formattedFee: string;
  formattedNetAmount: string;
  status: WithdrawalStatus;
  requestedAt: string;
  reviewedAt?: string | null;
  reviewedBy?: string | null;
  transactionReference?: string | null;
  rejectReason?: string | null;
  adminNote?: string | null;
}

export interface UserTransferItem {
  id: string;
  publicId: string;
  senderUserId: string;
  senderUsername: string;
  senderFullName: string;
  receiverUserId: string;
  receiverUsername: string;
  receiverFullName: string;
  amountMinor: number;
  feeMinor: number;
  netAmountMinor: number;
  formattedAmount: string;
  formattedFee: string;
  ledgerRef: string;
  status: "COMPLETED" | "PENDING" | "FAILED";
  note?: string | null;
  createdAt: string;
}

export type LedgerTransactionType =
  | "DEPOSIT"
  | "WITHDRAWAL"
  | "USER_TRANSFER"
  | "TICKET_PURCHASE"
  | "WINNING"
  | "REFUND"
  | "BONUS"
  | "COMMISSION"
  | "ADMIN_ADJUSTMENT";

export interface LedgerTransactionItem {
  id: string;
  publicId: string;
  transactionType: LedgerTransactionType;
  userId: string;
  username: string;
  userFullName: string;
  amountMinor: number;
  formattedAmount: string;
  direction: "CREDIT" | "DEBIT";
  status: "COMPLETED" | "PENDING" | "FAILED";
  referenceType: string;
  referenceId: string;
  createdAt: string;
  note?: string;
}

export interface ActiveDrawOverview {
  id: string;
  type: "MEGA" | "DAILY" | "HOURLY";
  name: string;
  sequenceNumber: string;
  ticketPriceMinor: number;
  formattedTicketPrice: string;
  jackpotMinor: number;
  formattedJackpot: string;
  ticketsSold: number;
  saleClosesAt: string;
  drawAt: string;
  status: "OPEN" | "SCHEDULED" | "CLOSED" | "PROCESSING";
  digitLength: number;
}

export interface DashboardKPIs {
  totalRevenue: string;
  totalRevenueMinor: number;
  totalRevenueDelta: string;
  todayTicketSales: string;
  todayTicketSalesMinor: number;
  todayTicketSalesCount: number;
  activeUsers: number;
  activeUsersDelta: string;
  pendingDepositsCount: number;
  pendingDepositsAmount: string;
  pendingWithdrawalsCount: number;
  pendingWithdrawalsAmount: string;
  activeDrawsCount: number;
}
