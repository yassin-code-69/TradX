import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "./client";

export interface ApproveDepositInput {
  depositId: string;
  note?: string;
}

export interface RejectDepositInput {
  depositId: string;
  reason: string;
}

export interface ApproveWithdrawalInput {
  withdrawalId: string;
  transactionReference?: string;
  note?: string;
}

export interface RejectWithdrawalInput {
  withdrawalId: string;
  reason: string;
}

export interface AdminAdjustBalanceInput {
  userId: string;
  amountMinor: number | string;
  type: "CREDIT" | "DEBIT";
  reason: string;
  note?: string;
}

export interface PublishResultInput {
  draw_id: number | string;
  winning_number: string;
  result_hash?: string;
}

export interface CreateDrawInputPayload {
  draw_type_id?: number;
  draw_type_code?: "MEGA" | "DAILY" | "HOURLY";
  sequence_number?: string;
  ticket_price_minor?: number;
  sale_open_at: string;
  sale_close_at: string;
  draw_at: string;
  status?:
    | "DRAFT"
    | "SCHEDULED"
    | "OPEN"
    | "CLOSED"
    | "PROCESSING"
    | "COMPLETED"
    | "CANCELLED";
}

export interface UpdateDrawStatusInput {
  drawId: number | string;
  status:
    | "DRAFT"
    | "SCHEDULED"
    | "OPEN"
    | "CLOSED"
    | "PROCESSING"
    | "COMPLETED"
    | "CANCELLED";
}

/**
 * Hook to approve a manual deposit and credit user wallet
 */
export function useApproveDeposit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ depositId, note }: ApproveDepositInput) => {
      return apiClient.post(`/api/v1/admin/deposits/${depositId}/approve`, {
        note,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "deposits"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "finance"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "wallet"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "ledger"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "kpis"] });
    },
  });
}

/**
 * Hook to reject a manual deposit request
 */
export function useRejectDeposit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ depositId, reason }: RejectDepositInput) => {
      return apiClient.post(`/api/v1/admin/deposits/${depositId}/reject`, {
        reason,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "deposits"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "finance"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "kpis"] });
    },
  });
}

/**
 * Hook to approve a withdrawal payout request
 */
export function useApproveWithdrawal() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      withdrawalId,
      transactionReference,
      note,
    }: ApproveWithdrawalInput) => {
      return apiClient.post(
        `/api/v1/admin/withdrawals/${withdrawalId}/approve`,
        {
          transactionReference,
          note,
        },
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "withdrawals"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "finance"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "ledger"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "kpis"] });
    },
  });
}

/**
 * Hook to reject a withdrawal request and release locked balance
 */
export function useRejectWithdrawal() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ withdrawalId, reason }: RejectWithdrawalInput) => {
      return apiClient.post(
        `/api/v1/admin/withdrawals/${withdrawalId}/reject`,
        {
          reason,
        },
      );
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "withdrawals"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "finance"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "wallet"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "kpis"] });
    },
  });
}

/**
 * Hook for administrative balance adjustment (credit/debit)
 */
export function useAdminAdjustBalance() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: AdminAdjustBalanceInput) => {
      return apiClient.post("/api/v1/admin/wallet/adjust", data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "wallet"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "finance"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "ledger"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "kpis"] });
    },
  });
}

/**
 * Hook to publish draw result and trigger winner calculation
 */
export function usePublishResult() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: PublishResultInput) => {
      return apiClient.post("/api/v1/admin/results/publish", data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "results"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "draws"] });
      queryClient.invalidateQueries({ queryKey: ["results"] });
      queryClient.invalidateQueries({ queryKey: ["draws"] });
    },
  });
}

/**
 * Hook to create a new draw
 */
export function useCreateDraw() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: CreateDrawInputPayload) => {
      return apiClient.post("/api/v1/admin/draws", data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "draws"] });
      queryClient.invalidateQueries({ queryKey: ["draws"] });
    },
  });
}

/**
 * Hook to update draw status
 */
export function useUpdateDrawStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ drawId, status }: UpdateDrawStatusInput) => {
      return apiClient.patch(`/api/v1/admin/draws/${drawId}/status`, {
        status,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "draws"] });
      queryClient.invalidateQueries({ queryKey: ["draws"] });
    },
  });
}
