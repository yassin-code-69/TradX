import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';

enum TxType { all, addMoney, withdraw, tickets }

class TransactionItem {
  final String title;
  final String date;
  final String amount;
  final bool isCredit;
  final TxType category;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TxType _selectedTab = TxType.all;
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction History',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab(TxType.all, 'All'),
                    const SizedBox(width: 8),
                    _buildTab(TxType.addMoney, 'Add Money'),
                    const SizedBox(width: 8),
                    _buildTab(TxType.withdraw, 'Withdraw'),
                    const SizedBox(width: 8),
                    _buildTab(TxType.tickets, 'Tickets'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Transactions List
            Expanded(
              child: ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  final transactions = _appState.transactions;
                  final filteredList = _selectedTab == TxType.all
                      ? transactions
                      : transactions.where((t) => t.category == _selectedTab).toList();

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Text(
                        'No transactions found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = filteredList[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            // Icon Circle
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tx.iconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(tx.icon, color: tx.iconColor, size: 20),
                            ),
                            const SizedBox(width: 12),

                            // Title & Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.date,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount
                            Text(
                              tx.amount,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: tx.isCredit ? AppColors.greenLight : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(TxType type, String label) {
    final bool isSelected = _selectedTab == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D28D9) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purpleLight : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
