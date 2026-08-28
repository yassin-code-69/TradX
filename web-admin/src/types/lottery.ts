export type DrawTypeCode = "MEGA" | "DAILY" | "HOURLY";

export type DrawStatus =
  | "DRAFT"
  | "SCHEDULED"
  | "OPEN"
  | "CLOSED"
  | "PROCESSING"
  | "COMPLETED"
  | "CANCELLED";

export interface DrawType {
  id: number;
  code: DrawTypeCode;
  name: string;
  digit_length: number;
  default_ticket_price_minor: number;
  status: "ACTIVE" | "INACTIVE";
}

export interface Draw {
  id: number;
  public_id: string;
  draw_type_id: number;
  draw_type_code: DrawTypeCode;
  draw_type_name: string;
  sequence_number: string;
  ticket_price_minor: number;
  sale_open_at: string;
  sale_close_at: string;
  draw_at: string;
  status: DrawStatus;
  total_tickets: number;
  total_sales_minor: number;
  created_by?: string;
  created_at: string;
  updated_at?: string;
}

export interface CreateDrawInput {
  draw_type_code: DrawTypeCode;
  sequence_number: string;
  ticket_price_minor: number;
  sale_open_at: string;
  sale_close_at: string;
  draw_at: string;
  status?: DrawStatus;
}

export type TicketStatus = "ACTIVE" | "WON" | "LOST" | "CANCELLED" | "REFUNDED";

export interface Ticket {
  id: number;
  public_id: string;
  order_id: number;
  order_public_id: string;
  user_id: string;
  user_name: string;
  user_phone: string;
  draw_id: number;
  draw_sequence: string;
  draw_type_code: DrawTypeCode;
  draw_type_name: string;
  selected_number: string; // Preserves leading zeroes e.g. "0012345", "007"
  ticket_price_minor: number;
  quantity: number;
  status: TicketStatus;
  is_winner: boolean;
  prize_amount_minor?: number;
  winning_tier?: string;
  payment_method: string;
  transaction_ref: string;
  created_at: string;
  updated_at?: string;
}

export interface DrawResult {
  id: number;
  public_id: string;
  draw_id: number;
  draw_public_id?: string;
  draw_sequence_number: string;
  draw_type_code: DrawTypeCode;
  draw_type_name: string;
  winning_number: string; // Preserves leading zeroes
  result_hash?: string;
  published_by: string;
  published_at: string;
  draw_at: string;
  created_at: string;
  total_tickets: number;
  total_sales_minor: number;
  winners_count: number;
  total_prize_paid_minor: number;
  status: "COMPLETED" | "PROCESSING";
}

export interface WinnerBreakdownTier {
  id: string;
  tier_name: string;
  match_type: string;
  match_condition: string;
  matched_digits: string;
  prize_amount_minor: number;
  count: number;
  total_payout_minor: number;
  paid_status: "PAID" | "PENDING";
}

export interface WinnerItem {
  id: number;
  public_id: string;
  draw_id: number;
  ticket_id: number;
  ticket_public_id: string;
  user_id: string;
  user_name: string;
  user_phone: string;
  prize_rule_name: string;
  match_type: string;
  matched_digits: string;
  selected_number: string;
  winning_number: string;
  prize_amount_minor: number;
  status: "PAID" | "PENDING" | "FAILED";
  paid_at?: string;
  created_at: string;
}

export interface PaymentMethodItem {
  id: string;
  code: "BKASH" | "NAGAD" | "ROCKET" | "BANK";
  name: string;
  type: "MOBILE_BANKING" | "BANK_TRANSFER";
  accountNumber: string;
  accountName: string;
  instructions: string;
  minimumDepositMinor: number;
  maximumDepositMinor: number;
  minimumWithdrawMinor: number;
  maximumWithdrawMinor: number;
  depositFeePercentageBasisPoints: number;
  depositFeeFixedMinor: number;
  withdrawFeePercentageBasisPoints: number;
  withdrawFeeFixedMinor: number;
  depositEnabled: boolean;
  withdrawEnabled: boolean;
  status: "ACTIVE" | "INACTIVE";
  displayOrder: number;
  updatedAt: string;
}

export interface PlatformGeneralSettings {
  platformName: string;
  supportEmail: string;
  supportPhone: string;
  supportWhatsapp: string;
  timezone: string;
  currency: string;
  autoCloseBufferMinutes: number;
  maxTicketsPerOrder: number;
  maintenanceMode: boolean;
  allowUserTransfers: boolean;
  allowWithdrawals: boolean;
  enableHourlyDraws: boolean;
  enableDailyDraws: boolean;
  enableMegaDraws: boolean;
  enableReferralProgram: boolean;
  enablePromotionalBanners: boolean;
  dailyTransferLimitMinor: number;
  minTransferMinor: number;
  maxTransferMinor: number;
  transferFeeBps: number;
}
