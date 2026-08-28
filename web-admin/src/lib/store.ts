import { create } from "zustand";
import type {
  ActiveDrawOverview,
  DashboardKPIs,
  DepositItem,
  LedgerTransactionItem,
  UserItem,
  UserStatus,
  UserTransferItem,
  WithdrawalItem,
} from "@/types";
import type {
  CreateDrawInput,
  Draw,
  DrawResult,
  DrawStatus,
  PaymentMethodItem,
  PlatformGeneralSettings,
  Ticket,
  WinnerBreakdownTier,
} from "@/types/lottery";
import { formatBDT } from "./formatters";
import {
  activeDraws,
  initialDeposits,
  initialKPIs,
  initialLedgerTransactions,
  initialTransfers,
  initialUsers,
  initialWithdrawals,
} from "./mockData";

interface AdminStoreState {
  users: UserItem[];
  deposits: DepositItem[];
  withdrawals: WithdrawalItem[];
  transfers: UserTransferItem[];
  ledgerTransactions: LedgerTransactionItem[];
  draws: ActiveDrawOverview[];
  kpis: DashboardKPIs;

  // Actions
  approveDeposit: (depositId: string, note?: string) => void;
  rejectDeposit: (depositId: string, reason: string) => void;
  approveWithdrawal: (
    withdrawalId: string,
    transactionReference?: string,
    note?: string,
  ) => void;
  rejectWithdrawal: (withdrawalId: string, reason: string) => void;
  adjustUserBalance: (
    userId: string,
    type: "CREDIT" | "DEBIT",
    amountMinor: number,
    reason: string,
    note?: string,
  ) => void;
  toggleUserStatus: (userId: string, newStatus: UserStatus) => void;
}

export const useAdminStore = create<AdminStoreState>((set) => ({
  users: initialUsers,
  deposits: initialDeposits,
  withdrawals: initialWithdrawals,
  transfers: initialTransfers,
  ledgerTransactions: initialLedgerTransactions,
  draws: activeDraws,
  kpis: initialKPIs,

  approveDeposit: (depositId, note) =>
    set((state) => {
      const deposit = state.deposits.find((d) => d.id === depositId);
      if (!deposit || deposit.status !== "PENDING") return state;

      const now = new Date().toISOString();
      const updatedDeposits = state.deposits.map((d) =>
        d.id === depositId
          ? {
              ...d,
              status: "APPROVED" as const,
              reviewedAt: now,
              reviewedBy: "Shahin Ahmed (Admin)",
              adminNote: note || "Approved via Admin Command Center",
            }
          : d,
      );

      // Credit user wallet
      const updatedUsers = state.users.map((u) =>
        u.id === deposit.userId
          ? {
              ...u,
              availableBalanceMinor:
                u.availableBalanceMinor + deposit.amountMinor,
              totalDepositsMinor: u.totalDepositsMinor + deposit.amountMinor,
              updatedAt: now,
            }
          : u,
      );

      // Ledger entry
      const newLedgerTx: LedgerTransactionItem = {
        id: `ltx-${Date.now()}`,
        publicId: `ltx-${Math.random().toString(36).substring(2, 9)}`,
        transactionType: "DEPOSIT",
        userId: deposit.userId,
        username: deposit.username,
        userFullName: deposit.userFullName,
        amountMinor: deposit.amountMinor,
        formattedAmount: deposit.formattedAmount,
        direction: "CREDIT",
        status: "COMPLETED",
        referenceType: "DEPOSIT_REQUEST",
        referenceId: deposit.id,
        createdAt: now,
        note: `Approved deposit via ${deposit.paymentMethod} (${deposit.providerTransactionId})`,
      };

      const pendingDepositsCount = Math.max(
        0,
        state.kpis.pendingDepositsCount - 1,
      );

      return {
        deposits: updatedDeposits,
        users: updatedUsers,
        ledgerTransactions: [newLedgerTx, ...state.ledgerTransactions],
        kpis: {
          ...state.kpis,
          pendingDepositsCount,
        },
      };
    }),

  rejectDeposit: (depositId, reason) =>
    set((state) => {
      const deposit = state.deposits.find((d) => d.id === depositId);
      if (!deposit || deposit.status !== "PENDING") return state;

      const now = new Date().toISOString();
      const updatedDeposits = state.deposits.map((d) =>
        d.id === depositId
          ? {
              ...d,
              status: "REJECTED" as const,
              reviewedAt: now,
              reviewedBy: "Shahin Ahmed (Admin)",
              rejectReason: reason,
            }
          : d,
      );

      const pendingDepositsCount = Math.max(
        0,
        state.kpis.pendingDepositsCount - 1,
      );

      return {
        deposits: updatedDeposits,
        kpis: {
          ...state.kpis,
          pendingDepositsCount,
        },
      };
    }),

  approveWithdrawal: (withdrawalId, transactionReference, note) =>
    set((state) => {
      const withdrawal = state.withdrawals.find((w) => w.id === withdrawalId);
      if (!withdrawal || withdrawal.status !== "PENDING") return state;

      const now = new Date().toISOString();
      const updatedWithdrawals = state.withdrawals.map((w) =>
        w.id === withdrawalId
          ? {
              ...w,
              status: "APPROVED" as const,
              reviewedAt: now,
              reviewedBy: "Shahin Ahmed (Admin)",
              transactionReference:
                transactionReference ||
                `TXN-REF-${Date.now().toString().slice(-6)}`,
              adminNote: note || "Disbursed to user account",
            }
          : w,
      );

      // User locked balance is cleared
      const updatedUsers = state.users.map((u) =>
        u.id === withdrawal.userId
          ? {
              ...u,
              lockedBalanceMinor: Math.max(
                0,
                u.lockedBalanceMinor - withdrawal.amountMinor,
              ),
              totalWithdrawalsMinor:
                u.totalWithdrawalsMinor + withdrawal.amountMinor,
              updatedAt: now,
            }
          : u,
      );

      // Ledger entry
      const newLedgerTx: LedgerTransactionItem = {
        id: `ltx-${Date.now()}`,
        publicId: `ltx-${Math.random().toString(36).substring(2, 9)}`,
        transactionType: "WITHDRAWAL",
        userId: withdrawal.userId,
        username: withdrawal.username,
        userFullName: withdrawal.userFullName,
        amountMinor: withdrawal.amountMinor,
        formattedAmount: withdrawal.formattedAmount,
        direction: "DEBIT",
        status: "COMPLETED",
        referenceType: "WITHDRAWAL_REQUEST",
        referenceId: withdrawal.id,
        createdAt: now,
        note: `Approved withdrawal to ${withdrawal.paymentMethod} (${withdrawal.receiverAccount})`,
      };

      const pendingWithdrawalsCount = Math.max(
        0,
        state.kpis.pendingWithdrawalsCount - 1,
      );

      return {
        withdrawals: updatedWithdrawals,
        users: updatedUsers,
        ledgerTransactions: [newLedgerTx, ...state.ledgerTransactions],
        kpis: {
          ...state.kpis,
          pendingWithdrawalsCount,
        },
      };
    }),

  rejectWithdrawal: (withdrawalId, reason) =>
    set((state) => {
      const withdrawal = state.withdrawals.find((w) => w.id === withdrawalId);
      if (!withdrawal || withdrawal.status !== "PENDING") return state;

      const now = new Date().toISOString();
      const updatedWithdrawals = state.withdrawals.map((w) =>
        w.id === withdrawalId
          ? {
              ...w,
              status: "REJECTED" as const,
              reviewedAt: now,
              reviewedBy: "Shahin Ahmed (Admin)",
              rejectReason: reason,
            }
          : w,
      );

      // Return funds from locked balance back to available balance
      const updatedUsers = state.users.map((u) =>
        u.id === withdrawal.userId
          ? {
              ...u,
              lockedBalanceMinor: Math.max(
                0,
                u.lockedBalanceMinor - withdrawal.amountMinor,
              ),
              availableBalanceMinor:
                u.availableBalanceMinor + withdrawal.amountMinor,
              updatedAt: now,
            }
          : u,
      );

      const pendingWithdrawalsCount = Math.max(
        0,
        state.kpis.pendingWithdrawalsCount - 1,
      );

      return {
        withdrawals: updatedWithdrawals,
        users: updatedUsers,
        kpis: {
          ...state.kpis,
          pendingWithdrawalsCount,
        },
      };
    }),

  adjustUserBalance: (userId, type, amountMinor, reason, note) =>
    set((state) => {
      const user = state.users.find((u) => u.id === userId);
      if (!user) return state;

      const now = new Date().toISOString();
      const newAvailable =
        type === "CREDIT"
          ? user.availableBalanceMinor + amountMinor
          : Math.max(0, user.availableBalanceMinor - amountMinor);

      const updatedUsers = state.users.map((u) =>
        u.id === userId
          ? {
              ...u,
              availableBalanceMinor: newAvailable,
              updatedAt: now,
            }
          : u,
      );

      const newLedgerTx: LedgerTransactionItem = {
        id: `ltx-${Date.now()}`,
        publicId: `ltx-${Math.random().toString(36).substring(2, 9)}`,
        transactionType: "ADMIN_ADJUSTMENT",
        userId: user.id,
        username: user.username,
        userFullName: user.fullName,
        amountMinor,
        formattedAmount: formatBDT(amountMinor),
        direction: type,
        status: "COMPLETED",
        referenceType: "ADMIN_OPERATION",
        referenceId: `adj-${Date.now().toString().slice(-6)}`,
        createdAt: now,
        note: `Balance ${type}: ${reason}${note ? ` (${note})` : ""}`,
      };

      return {
        users: updatedUsers,
        ledgerTransactions: [newLedgerTx, ...state.ledgerTransactions],
      };
    }),

  toggleUserStatus: (userId, newStatus) =>
    set((state) => {
      const now = new Date().toISOString();
      const updatedUsers = state.users.map((u) =>
        u.id === userId
          ? {
              ...u,
              status: newStatus,
              updatedAt: now,
            }
          : u,
      );
      return { users: updatedUsers };
    }),
}));

// ==================== LOTTERY STORE ====================

const initialLotteryDraws: Draw[] = [
  {
    id: 1,
    public_id: "drw-mega-104",
    draw_type_id: 1,
    draw_type_code: "MEGA",
    draw_type_name: "Mega Jackpot Draw",
    sequence_number: "MG-104",
    ticket_price_minor: 5000,
    sale_open_at: new Date(Date.now() - 4 * 24 * 3600 * 1000).toISOString(),
    sale_close_at: new Date(
      Date.now() + 3 * 24 * 3600 * 1000 + 14 * 3600 * 1000,
    ).toISOString(),
    draw_at: new Date(
      Date.now() + 3 * 24 * 3600 * 1000 + 15 * 3600 * 1000,
    ).toISOString(),
    status: "OPEN",
    total_tickets: 18920,
    total_sales_minor: 94600000,
    created_at: new Date(Date.now() - 5 * 24 * 3600 * 1000).toISOString(),
  },
  {
    id: 2,
    public_id: "drw-daily-1289",
    draw_type_id: 2,
    draw_type_code: "DAILY",
    draw_type_name: "Daily Golden Draw",
    sequence_number: "DL-1289",
    ticket_price_minor: 2000,
    sale_open_at: new Date(Date.now() - 12 * 3600 * 1000).toISOString(),
    sale_close_at: new Date(
      Date.now() + 2 * 3600 * 1000 + 45 * 60 * 1000,
    ).toISOString(),
    draw_at: new Date(Date.now() + 3 * 3600 * 1000).toISOString(),
    status: "OPEN",
    total_tickets: 6450,
    total_sales_minor: 12900000,
    created_at: new Date(Date.now() - 24 * 3600 * 1000).toISOString(),
  },
  {
    id: 3,
    public_id: "drw-hourly-3042",
    draw_type_id: 3,
    draw_type_code: "HOURLY",
    draw_type_name: "Hourly Rush Draw",
    sequence_number: "HR-3042",
    ticket_price_minor: 1000,
    sale_open_at: new Date(Date.now() - 40 * 60 * 1000).toISOString(),
    sale_close_at: new Date(Date.now() + 18 * 60 * 1000).toISOString(),
    draw_at: new Date(Date.now() + 20 * 60 * 1000).toISOString(),
    status: "OPEN",
    total_tickets: 1840,
    total_sales_minor: 1840000,
    created_at: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
  },
  {
    id: 4,
    public_id: "drw-daily-1288",
    draw_type_id: 2,
    draw_type_code: "DAILY",
    draw_type_name: "Daily Golden Draw",
    sequence_number: "DL-1288",
    ticket_price_minor: 2000,
    sale_open_at: new Date(Date.now() - 36 * 3600 * 1000).toISOString(),
    sale_close_at: new Date(Date.now() - 14 * 3600 * 1000).toISOString(),
    draw_at: new Date(Date.now() - 13 * 3600 * 1000).toISOString(),
    status: "COMPLETED",
    total_tickets: 8400,
    total_sales_minor: 16800000,
    created_at: new Date(Date.now() - 48 * 3600 * 1000).toISOString(),
  },
];

const initialLotteryTickets: Ticket[] = [
  {
    id: 1,
    public_id: "tkt-001982",
    order_id: 101,
    order_public_id: "ord-99128",
    user_id: "usr-001",
    user_name: "rahim_chy",
    user_phone: "+880 1712-345678",
    draw_id: 1,
    draw_sequence: "MG-104",
    draw_type_code: "MEGA",
    draw_type_name: "Mega Jackpot Draw",
    selected_number: "0012345",
    ticket_price_minor: 5000,
    quantity: 1,
    status: "ACTIVE",
    is_winner: false,
    payment_method: "bKash",
    transaction_ref: "TXN-991823",
    created_at: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
  },
  {
    id: 2,
    public_id: "tkt-001983",
    order_id: 102,
    order_public_id: "ord-99129",
    user_id: "usr-002",
    user_name: "tanvir_islam",
    user_phone: "+880 1823-998877",
    draw_id: 2,
    draw_sequence: "DL-1289",
    draw_type_code: "DAILY",
    draw_type_name: "Daily Golden Draw",
    selected_number: "782",
    ticket_price_minor: 2000,
    quantity: 1,
    status: "ACTIVE",
    is_winner: false,
    payment_method: "Nagad",
    transaction_ref: "TXN-991824",
    created_at: new Date(Date.now() - 3 * 3600 * 1000).toISOString(),
  },
  {
    id: 3,
    public_id: "tkt-001984",
    order_id: 103,
    order_public_id: "ord-99130",
    user_id: "usr-003",
    user_name: "sadia_akter",
    user_phone: "+880 1911-223344",
    draw_id: 4,
    draw_sequence: "DL-1288",
    draw_type_code: "DAILY",
    draw_type_name: "Daily Golden Draw",
    selected_number: "782",
    ticket_price_minor: 2000,
    quantity: 1,
    status: "WON",
    is_winner: true,
    prize_amount_minor: 250000,
    winning_tier: "1st Prize - 3 Exact Match",
    payment_method: "Wallet",
    transaction_ref: "TXN-991825",
    created_at: new Date(Date.now() - 16 * 3600 * 1000).toISOString(),
  },
];

const initialDrawResults: DrawResult[] = [
  {
    id: 1,
    public_id: "res-dl-1288",
    draw_id: 4,
    draw_sequence_number: "DL-1288",
    draw_type_code: "DAILY",
    draw_type_name: "Daily Golden Draw",
    winning_number: "782",
    result_hash: "SHA256:8f4c281e0998a44b1c7d23...",
    published_by: "Shahin Ahmed (Draw Manager)",
    published_at: new Date(Date.now() - 13 * 3600 * 1000).toISOString(),
    draw_at: new Date(Date.now() - 13 * 3600 * 1000).toISOString(),
    created_at: new Date(Date.now() - 13 * 3600 * 1000).toISOString(),
    total_tickets: 8400,
    total_sales_minor: 16800000,
    winners_count: 14,
    total_prize_paid_minor: 2800000,
    status: "COMPLETED",
  },
];

const initialWinnerBreakdowns: Record<number, WinnerBreakdownTier[]> = {
  4: [
    {
      id: "tier-1",
      tier_name: "1st Prize - 3 Exact Match",
      match_type: "EXACT",
      match_condition: "All 3 digits match in exact position",
      matched_digits: "782",
      prize_amount_minor: 250000,
      count: 2,
      total_payout_minor: 500000,
      paid_status: "PAID",
    },
    {
      id: "tier-2",
      tier_name: "2nd Prize - Last 2 Digits",
      match_type: "LAST_2",
      match_condition: "Last 2 digits match (82)",
      matched_digits: "82",
      prize_amount_minor: 50000,
      count: 12,
      total_payout_minor: 600000,
      paid_status: "PAID",
    },
  ],
};

export const defaultPlatformSettings: PlatformGeneralSettings = {
  platformName: "TRADEX Official Admin",
  supportEmail: "support@tradex.com",
  supportPhone: "+880 9612-889900",
  supportWhatsapp: "+880 1700-112233",
  timezone: "Asia/Dhaka (UTC+6)",
  currency: "BDT (৳)",
  autoCloseBufferMinutes: 10,
  maxTicketsPerOrder: 50,
  maintenanceMode: false,
  allowUserTransfers: true,
  allowWithdrawals: true,
  enableHourlyDraws: true,
  enableDailyDraws: true,
  enableMegaDraws: true,
  enableReferralProgram: true,
  enablePromotionalBanners: true,
  dailyTransferLimitMinor: 5000000,
  minTransferMinor: 10000,
  maxTransferMinor: 1000000,
  transferFeeBps: 100,
};

export const defaultPaymentMethods: PaymentMethodItem[] = [
  {
    id: "pm-1",
    code: "BKASH",
    name: "bKash Merchant",
    type: "MOBILE_BANKING",
    accountNumber: "01712-345678",
    accountName: "TRADEX Operations BD Ltd",
    instructions: "Send money to Merchant number and enter TrxID.",
    minimumDepositMinor: 10000,
    maximumDepositMinor: 2500000,
    minimumWithdrawMinor: 50000,
    maximumWithdrawMinor: 2500000,
    depositFeePercentageBasisPoints: 150,
    depositFeeFixedMinor: 0,
    withdrawFeePercentageBasisPoints: 180,
    withdrawFeeFixedMinor: 0,
    depositEnabled: true,
    withdrawEnabled: true,
    status: "ACTIVE",
    displayOrder: 1,
    updatedAt: new Date().toISOString(),
  },
  {
    id: "pm-2",
    code: "NAGAD",
    name: "Nagad Merchant",
    type: "MOBILE_BANKING",
    accountNumber: "01823-998877",
    accountName: "TRADEX Operations BD Ltd",
    instructions: "Send money via Nagad App/USSD and paste Transaction ID.",
    minimumDepositMinor: 10000,
    maximumDepositMinor: 2500000,
    minimumWithdrawMinor: 50000,
    maximumWithdrawMinor: 2500000,
    depositFeePercentageBasisPoints: 120,
    depositFeeFixedMinor: 0,
    withdrawFeePercentageBasisPoints: 150,
    withdrawFeeFixedMinor: 0,
    depositEnabled: true,
    withdrawEnabled: true,
    status: "ACTIVE",
    displayOrder: 2,
    updatedAt: new Date().toISOString(),
  },
  {
    id: "pm-3",
    code: "ROCKET",
    name: "Rocket Dutch-Bangla",
    type: "MOBILE_BANKING",
    accountNumber: "01911-223344-8",
    accountName: "TRADEX Operations BD Ltd",
    instructions: "Pay to Rocket Biller/Merchant ID and submit reference.",
    minimumDepositMinor: 10000,
    maximumDepositMinor: 2500000,
    minimumWithdrawMinor: 50000,
    maximumWithdrawMinor: 2500000,
    depositFeePercentageBasisPoints: 150,
    depositFeeFixedMinor: 0,
    withdrawFeePercentageBasisPoints: 180,
    withdrawFeeFixedMinor: 0,
    depositEnabled: true,
    withdrawEnabled: true,
    status: "ACTIVE",
    displayOrder: 3,
    updatedAt: new Date().toISOString(),
  },
  {
    id: "pm-4",
    code: "BANK",
    name: "City Bank Corporate AC",
    type: "BANK_TRANSFER",
    accountNumber: "1102983741001",
    accountName: "TRADEX Operations Bangladesh Ltd",
    instructions: "NPSB / BEFTN transfer. Include Public ID in remarks.",
    minimumDepositMinor: 500000,
    maximumDepositMinor: 10000000,
    minimumWithdrawMinor: 1000000,
    maximumWithdrawMinor: 10000000,
    depositFeePercentageBasisPoints: 0,
    depositFeeFixedMinor: 0,
    withdrawFeePercentageBasisPoints: 0,
    withdrawFeeFixedMinor: 0,
    depositEnabled: true,
    withdrawEnabled: true,
    status: "ACTIVE",
    displayOrder: 4,
    updatedAt: new Date().toISOString(),
  },
];

interface LotteryStoreState {
  draws: Draw[];
  tickets: Ticket[];
  results: DrawResult[];
  winnerBreakdowns: Record<number, WinnerBreakdownTier[]>;
  paymentMethods: PaymentMethodItem[];
  settings: PlatformGeneralSettings;

  addDraw: (input: CreateDrawInput) => Draw;
  updateDrawStatus: (drawId: number, status: DrawStatus) => void;
  publishWinningNumber: (
    drawId: number,
    winningNumber: string,
    hash?: string,
  ) => { result: DrawResult; winnersCount: number; totalPrizeMinor: number };

  updatePaymentMethod: (
    id: string,
    updates: Partial<PaymentMethodItem>,
  ) => void;
  addPaymentMethod: (
    newMethod: Omit<PaymentMethodItem, "id" | "updatedAt">,
  ) => void;
  updateSettings: (updates: Partial<PlatformGeneralSettings>) => void;
  resetToDefaults: () => void;
}

export const useLotteryStore = create<LotteryStoreState>((set) => ({
  draws: initialLotteryDraws,
  tickets: initialLotteryTickets,
  results: initialDrawResults,
  winnerBreakdowns: initialWinnerBreakdowns,
  paymentMethods: defaultPaymentMethods,
  settings: defaultPlatformSettings,

  addDraw: (input) => {
    let created!: Draw;
    set((state) => {
      const nextId = state.draws.length + 1;
      created = {
        id: nextId,
        public_id: `drw-${input.draw_type_code.toLowerCase()}-${nextId}`,
        draw_type_id:
          input.draw_type_code === "MEGA"
            ? 1
            : input.draw_type_code === "DAILY"
              ? 2
              : 3,
        draw_type_code: input.draw_type_code,
        draw_type_name:
          input.draw_type_code === "MEGA"
            ? "Mega Jackpot Draw"
            : input.draw_type_code === "DAILY"
              ? "Daily Golden Draw"
              : "Hourly Rush Draw",
        sequence_number: input.sequence_number,
        ticket_price_minor: input.ticket_price_minor,
        sale_open_at: input.sale_open_at,
        sale_close_at: input.sale_close_at,
        draw_at: input.draw_at,
        status: input.status || "SCHEDULED",
        total_tickets: 0,
        total_sales_minor: 0,
        created_at: new Date().toISOString(),
      };
      return { draws: [created, ...state.draws] };
    });
    return created;
  },

  updateDrawStatus: (drawId, status) =>
    set((state) => ({
      draws: state.draws.map((d) => (d.id === drawId ? { ...d, status } : d)),
    })),

  publishWinningNumber: (drawId, winningNumber, hash) => {
    let outcome!: {
      result: DrawResult;
      winnersCount: number;
      totalPrizeMinor: number;
    };
    set((state) => {
      const targetDraw = state.draws.find((d) => d.id === drawId);
      const now = new Date().toISOString();
      const updatedDraws = state.draws.map((d) =>
        d.id === drawId ? { ...d, status: "COMPLETED" as const } : d,
      );

      const newResult: DrawResult = {
        id: state.results.length + 1,
        public_id: `res-${drawId}-${Date.now()}`,
        draw_id: drawId,
        draw_sequence_number: targetDraw?.sequence_number || `DRW-${drawId}`,
        draw_type_code: targetDraw?.draw_type_code || "DAILY",
        draw_type_name: targetDraw?.draw_type_name || "Daily Golden Draw",
        winning_number: winningNumber,
        result_hash:
          hash || `SHA256:${Math.random().toString(36).substring(2, 18)}`,
        published_by: "Shahin Ahmed (Draw Manager)",
        published_at: now,
        draw_at: now,
        created_at: now,
        total_tickets: targetDraw?.total_tickets || 100,
        total_sales_minor: targetDraw?.total_sales_minor || 200000,
        winners_count: 5,
        total_prize_paid_minor: 500000,
        status: "COMPLETED",
      };

      outcome = {
        result: newResult,
        winnersCount: 5,
        totalPrizeMinor: 500000,
      };

      return {
        draws: updatedDraws,
        results: [newResult, ...state.results],
      };
    });
    return outcome;
  },

  updatePaymentMethod: (id, updates) =>
    set((state) => ({
      paymentMethods: state.paymentMethods.map((pm) =>
        pm.id === id
          ? { ...pm, ...updates, updatedAt: new Date().toISOString() }
          : pm,
      ),
    })),

  addPaymentMethod: (newMethod) =>
    set((state) => {
      const id = `pm-${Date.now()}`;
      const item: PaymentMethodItem = {
        ...newMethod,
        id,
        updatedAt: new Date().toISOString(),
      };
      return { paymentMethods: [...state.paymentMethods, item] };
    }),

  updateSettings: (updates) =>
    set((state) => ({
      settings: { ...state.settings, ...updates },
    })),

  resetToDefaults: () =>
    set({
      settings: defaultPlatformSettings,
      paymentMethods: defaultPaymentMethods,
    }),
}));
