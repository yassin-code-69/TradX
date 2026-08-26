import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

enum PaymentProvider {
  bkash,
  nagad,
  rocket,
  bank,
}

class PaymentMethodModel {
  final String id;
  final PaymentProvider provider;
  final String providerName;
  final String accountNumber;
  final String accountHolderName;
  final String accountType; // Personal, Agent, Merchant, Bank Account
  final String? bankName;
  final String? branchName;
  final String? routingNumber;
  final bool isDefault;
  final String instructions;
  final double minDeposit;
  final double maxDeposit;
  final double minWithdraw;
  final double maxWithdraw;

  const PaymentMethodModel({
    required this.id,
    required this.provider,
    required this.providerName,
    required this.accountNumber,
    required this.accountHolderName,
    this.accountType = 'Personal',
    this.bankName,
    this.branchName,
    this.routingNumber,
    this.isDefault = false,
    this.instructions = '',
    this.minDeposit = 100,
    this.maxDeposit = 25000,
    this.minWithdraw = 100,
    this.maxWithdraw = 25000,
  });

  PaymentMethodModel copyWith({
    String? id,
    PaymentProvider? provider,
    String? providerName,
    String? accountNumber,
    String? accountHolderName,
    String? accountType,
    String? bankName,
    String? branchName,
    String? routingNumber,
    bool? isDefault,
    String? instructions,
    double? minDeposit,
    double? maxDeposit,
    double? minWithdraw,
    double? maxWithdraw,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerName: providerName ?? this.providerName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountType: accountType ?? this.accountType,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      routingNumber: routingNumber ?? this.routingNumber,
      isDefault: isDefault ?? this.isDefault,
      instructions: instructions ?? this.instructions,
      minDeposit: minDeposit ?? this.minDeposit,
      maxDeposit: maxDeposit ?? this.maxDeposit,
      minWithdraw: minWithdraw ?? this.minWithdraw,
      maxWithdraw: maxWithdraw ?? this.maxWithdraw,
    );
  }

  Color get brandColor {
    switch (provider) {
      case PaymentProvider.bkash:
        return AppColors.bkash;
      case PaymentProvider.nagad:
        return AppColors.nagad;
      case PaymentProvider.rocket:
        return AppColors.rocket;
      case PaymentProvider.bank:
        return AppColors.bank;
    }
  }

  static const List<PaymentMethodModel> adminDepositAccounts = [
    PaymentMethodModel(
      id: 'adm_nagad',
      provider: PaymentProvider.nagad,
      providerName: 'নগদ (Nagad)',
      accountNumber: '01799-887766',
      accountHolderName: 'TRADEX Official Agent',
      accountType: 'Merchant / Agent (Cash Out / Send Money)',
      instructions: '1. Go to your Nagad App or dial *167#\n2. Send Money / Cash Out to the official number\n3. Copy the Transaction ID (TrxID)\n4. Enter the amount & TrxID below to verify',
      minDeposit: 100,
      maxDeposit: 25000,
    ),
    PaymentMethodModel(
      id: 'adm_bkash',
      provider: PaymentProvider.bkash,
      providerName: 'বিকাশ (bKash)',
      accountNumber: '01855-443322',
      accountHolderName: 'TRADEX Official Agent',
      accountType: 'Agent (Cash Out)',
      instructions: '1. Go to your bKash App or dial *247#\n2. Cash Out to the official Agent number\n3. Copy the TrxID\n4. Submit the transaction ID and screenshot below',
      minDeposit: 100,
      maxDeposit: 25000,
    ),
    PaymentMethodModel(
      id: 'adm_rocket',
      provider: PaymentProvider.rocket,
      providerName: 'Rocket',
      accountNumber: '01911-223344-8',
      accountHolderName: 'TRADEX Official Agent',
      accountType: 'Agent (Cash Out)',
      instructions: '1. Dial *322# or use Rocket App\n2. Transfer to the Rocket agent number\n3. Copy TxnId and submit below',
      minDeposit: 100,
      maxDeposit: 25000,
    ),
    PaymentMethodModel(
      id: 'adm_bank',
      provider: PaymentProvider.bank,
      providerName: 'Bank Transfer (City Bank)',
      accountNumber: '1102938475001',
      accountHolderName: 'TRADEX GLOBAL VENTURES LTD',
      accountType: 'Corporate Current Account',
      bankName: 'The City Bank Ltd',
      branchName: 'Gulshan Branch',
      routingNumber: '225271829',
      instructions: '1. Initiate BEFTN / NPSB / RTGS transfer\n2. Put your Username in the transfer remarks\n3. Attach transfer receipt screenshot and submit',
      minDeposit: 500,
      maxDeposit: 100000,
    ),
  ];
}
