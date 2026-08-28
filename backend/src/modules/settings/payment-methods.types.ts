export interface PaymentMethodItem {
  id: string;
  code: string;
  name: string;
  type: string;
  accountNumber: string;
  accountName: string;
  instructions: string;
  minimumDepositMinor: string;
  maximumDepositMinor: string;
  minimumWithdrawMinor: string;
  maximumWithdrawMinor: string;
  formattedMinDeposit: string;
  formattedMaxDeposit: string;
  formattedMinWithdraw: string;
  formattedMaxWithdraw: string;
  depositFeePercentageBasisPoints: number;
  depositFeeFixedMinor: string;
  withdrawFeePercentageBasisPoints: number;
  withdrawFeeFixedMinor: string;
  depositEnabled: boolean;
  withdrawEnabled: boolean;
  status: string;
  displayOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreatePaymentMethodInput {
  code: string;
  name: string;
  type?: string;
  accountNumber: string;
  accountName: string;
  instructions: string;
  minimumDepositMinor?: number | string | bigint;
  maximumDepositMinor?: number | string | bigint;
  minimumWithdrawMinor?: number | string | bigint;
  maximumWithdrawMinor?: number | string | bigint;
  depositFeePercentageBasisPoints?: number;
  depositFeeFixedMinor?: number | string | bigint;
  withdrawFeePercentageBasisPoints?: number;
  withdrawFeeFixedMinor?: number | string | bigint;
  depositEnabled?: boolean;
  withdrawEnabled?: boolean;
  status?: 'ACTIVE' | 'INACTIVE';
  displayOrder?: number;
}

export interface UpdatePaymentMethodInput {
  name?: string;
  type?: string;
  accountNumber?: string;
  accountName?: string;
  instructions?: string;
  minimumDepositMinor?: number | string | bigint;
  maximumDepositMinor?: number | string | bigint;
  minimumWithdrawMinor?: number | string | bigint;
  maximumWithdrawMinor?: number | string | bigint;
  depositFeePercentageBasisPoints?: number;
  depositFeeFixedMinor?: number | string | bigint;
  withdrawFeePercentageBasisPoints?: number;
  withdrawFeeFixedMinor?: number | string | bigint;
  depositEnabled?: boolean;
  withdrawEnabled?: boolean;
  status?: 'ACTIVE' | 'INACTIVE';
  displayOrder?: number;
}
