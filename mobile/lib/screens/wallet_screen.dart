import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/transaction_model.dart';
import 'package:tradex/screens/add_money_screen.dart';
import 'package:tradex/screens/send_money_screen.dart';
import 'package:tradex/screens/transaction_history_screen.dart';
import 'package:tradex/screens/withdraw_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/draw_icons.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showLockedBalanceInfo(BuildContext context, AppState appState) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBgElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorderHighlight, width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.goldPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Locked Balance Info',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Locked Amount: ৳ ${appState.formattedLockedBalance}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Locked funds represent money temporarily held for active pending withdrawals or reserved game tickets. Once processed or settled, the funds are debited or released back to your available balance.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'UNDERSTOOD',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionReceipt(BuildContext context, TransactionModel tx) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorderHighlight, width: 1.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              TradexReceiptCard(
                title: tx.title,
                status: tx.status.name.toUpperCase(),
                statusColor: tx.statusColor,
                amount: tx.formattedAmount,
                idLabel: 'TRANSACTION ID',
                idValue: tx.id,
                details: [
                  MapEntry('Description', tx.description),
                  if (tx.method != null) MapEntry('Payment Method', tx.method!),
                  if (tx.recipientOrSender != null)
                    MapEntry(
                      tx.isCredit ? 'Sender Account' : 'Recipient Account',
                      tx.recipientOrSender!,
                    ),
                  if (tx.fee > 0) MapEntry('Processing Fee', '৳ ${tx.fee.toStringAsFixed(2)}'),
                  if (tx.note != null) MapEntry('Remarks / Reference', tx.note!),
                  MapEntry('Date & Time', tx.formattedDate),
                ],
                onCopyId: () {
                  Clipboard.setData(ClipboardData(text: tx.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction ID copied!'),
                      backgroundColor: AppColors.greenDark,
                    ),
                  );
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction receipt shared!'),
                      backgroundColor: AppColors.cardBgElevated,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TradexButton(
                text: 'CLOSE RECEIPT',
                variant: TradexButtonVariant.outline,
                height: 46,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              appState.setTabIndex(0);
            }
          },
        ),
        title: Text(
          'Wallet & Finances',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.goldLight, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Financial Overview Card
              ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF161A2B), Color(0xFF0D101C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.cardBorderHighlight,
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleDark.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL BALANCE',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const WalletChestGraphic(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '৳',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appState.formattedBalance,
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 14),

                        // Available vs Locked Breakdown
                        Row(
                          children: [
                            // Available Balance
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.greenLight,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Available',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '৳ ${appState.formattedAvailableBalance}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              width: 1,
                              height: 34,
                              color: AppColors.cardBorder,
                            ),
                            const SizedBox(width: 16),

                            // Locked Balance with Info Tooltip
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showLockedBalanceInfo(context, appState),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.lock_outline_rounded,
                                          color: AppColors.goldAccent,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Locked',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: AppColors.textMuted,
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '৳ ${appState.formattedLockedBalance}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.goldAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 2. Action Buttons: [Add Money], [Send Money], [Withdraw]
              Row(
                children: [
                  // Add Money
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleDark.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'ADD MONEY',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send Money (P2P Transfer)
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyanAccent.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SendMoneyScreen()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, color: Colors.white, size: 17),
                              const SizedBox(width: 6),
                              Text(
                                'SEND MONEY',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Withdraw
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.cardBgElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderHighlight, width: 1.2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WithdrawScreen()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'WITHDRAW',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Financial Stats Summary
              Text(
                'Financial Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.cyanAccent,
                          label: 'Total Deposits Added',
                          value: '৳ ${appState.totalAdded.toStringAsFixed(0)}',
                        ),
                        const Divider(color: AppColors.divider, height: 18),
                        _buildSummaryRow(
                          icon: Icons.lock_outline_rounded,
                          iconColor: AppColors.orangeAccent,
                          label: 'Total Withdrawn',
                          value: '৳ ${appState.totalWithdrawn.toStringAsFixed(0)}',
                        ),
                        const Divider(color: AppColors.divider, height: 18),
                        _buildSummaryRow(
                          icon: Icons.emoji_events_outlined,
                          iconColor: AppColors.goldPrimary,
                          label: 'Lottery Winnings',
                          value: '৳ ${appState.winningAmount.toStringAsFixed(0)}',
                          valueColor: AppColors.goldAccent,
                        ),
                        const Divider(color: AppColors.divider, height: 18),
                        _buildSummaryRow(
                          icon: Icons.confirmation_number_outlined,
                          iconColor: AppColors.purpleLight,
                          label: 'Spent on Tickets',
                          value: '৳ ${appState.usedForTickets.toStringAsFixed(0)}',
                        ),
                        const Divider(color: AppColors.divider, height: 18),
                        _buildSummaryRow(
                          icon: Icons.card_giftcard_rounded,
                          iconColor: AppColors.greenLight,
                          label: 'Bonus & Referral Earnings',
                          value: '৳ ${appState.bonus.toStringAsFixed(0)}',
                          valueColor: AppColors.greenLight,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 4. Recent Transactions Section with "View All" link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.goldAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recent Transactions List (Top 5)
              ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  final transactions = appState.transactions;
                  if (transactions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No transactions recorded yet',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final displayList = transactions.take(5).toList();

                  return Column(
                    children: displayList.map((tx) {
                      return GestureDetector(
                        onTap: () => _showTransactionReceipt(context, tx),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tx.iconBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tx.icon, color: tx.iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tx.formattedDate,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tx.formattedAmount,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: tx.isCredit ? AppColors.greenLight : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  TradexStatusChip(
                                    label: tx.status.name.toUpperCase(),
                                    color: tx.statusColor,
                                    fontSize: 8.5,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Promotional Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.purpleAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purpleAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: AppColors.purpleLight, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant P2P Transfer & Fast Payouts',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Send money to friends instantly with 0% fee using @username.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
