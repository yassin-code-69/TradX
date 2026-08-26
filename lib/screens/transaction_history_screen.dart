import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/transaction_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

enum TransactionFilterTab {
  all,
  deposit,
  withdraw,
  tickets,
  winnings,
  transfers,
  bonus,
}

class TransactionHistoryScreen extends StatefulWidget {
  final TransactionFilterTab initialTab;

  const TransactionHistoryScreen({
    super.key,
    this.initialTab = TransactionFilterTab.all,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late TransactionFilterTab _selectedTab;
  final TextEditingController _searchController = TextEditingController();
  final AppState _appState = AppState();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allList) {
    return allList.where((tx) {
      // 1. Tab category filter
      bool matchesTab = true;
      switch (_selectedTab) {
        case TransactionFilterTab.all:
          matchesTab = true;
          break;
        case TransactionFilterTab.deposit:
          matchesTab = tx.type == TransactionType.deposit;
          break;
        case TransactionFilterTab.withdraw:
          matchesTab = tx.type == TransactionType.withdraw;
          break;
        case TransactionFilterTab.tickets:
          matchesTab = tx.type == TransactionType.ticketPurchase;
          break;
        case TransactionFilterTab.winnings:
          matchesTab = tx.type == TransactionType.winning;
          break;
        case TransactionFilterTab.transfers:
          matchesTab = tx.type == TransactionType.transferSent ||
              tx.type == TransactionType.transferReceived;
          break;
        case TransactionFilterTab.bonus:
          matchesTab = tx.type == TransactionType.bonus ||
              tx.type == TransactionType.commission ||
              tx.type == TransactionType.refund;
          break;
      }

      if (!matchesTab) return false;

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final inId = tx.id.toLowerCase().contains(query);
        final inTitle = tx.title.toLowerCase().contains(query);
        final inDesc = tx.description.toLowerCase().contains(query);
        final inMethod = tx.method?.toLowerCase().contains(query) ?? false;
        final inRecipient = tx.recipientOrSender?.toLowerCase().contains(query) ?? false;
        final inTicket = tx.relatedTicketNumber?.toLowerCase().contains(query) ?? false;

        return inId || inTitle || inDesc || inMethod || inRecipient || inTicket;
      }

      return true;
    }).toList();
  }

  void _showTransactionDetail(TransactionModel tx) {
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
                  if (tx.method != null) MapEntry('Method / Gateway', tx.method!),
                  if (tx.recipientOrSender != null)
                    MapEntry(
                      tx.isCredit ? 'Sender Details' : 'Recipient Details',
                      tx.recipientOrSender!,
                    ),
                  if (tx.relatedDrawTitle != null) MapEntry('Related Draw', tx.relatedDrawTitle!),
                  if (tx.relatedTicketNumber != null)
                    MapEntry('Ticket Picked', tx.relatedTicketNumber!),
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
                      content: Text('Receipt shared!'),
                      backgroundColor: AppColors.cardBgElevated,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              TradexButton(
                text: 'CLOSE RECEIPT',
                variant: TradexButtonVariant.outline,
                height: 48,
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
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    hintText: 'Search by TXID, draw, recipient or notes...',
                    hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // 2. Horizontal Filter Tabs Bar
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTab(TransactionFilterTab.all, 'All'),
                  const SizedBox(width: 8),
                  _buildTab(TransactionFilterTab.deposit, 'Add Money'),
                  const SizedBox(width: 8),
                  _buildTab(TransactionFilterTab.withdraw, 'Withdraw'),
                  const SizedBox(width: 8),
                  _buildTab(TransactionFilterTab.tickets, 'Tickets'),
                  const SizedBox(width: 8),
                  _buildTab(TransactionFilterTab.winnings, 'Winnings'),
                  const SizedBox(width: 8),
                  _buildTab(TransactionFilterTab.transfers, 'Transfers'),
                  const SizedBox(width: 8),
                  _buildTab(TransactionFilterTab.bonus, 'Bonus'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Transactions Ledger
            Expanded(
              child: ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  final allList = _appState.transactions;
                  final filteredList = _getFilteredTransactions(allList);

                  if (filteredList.isEmpty) {
                    return TradexEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Transactions Found',
                      message: _searchQuery.isNotEmpty
                          ? 'No transaction matches query "$_searchQuery".'
                          : 'No transactions recorded under this category yet.',
                      iconColor: AppColors.purpleLight,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: filteredList.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = filteredList[index];
                      return GestureDetector(
                        onTap: () => _showTransactionDetail(tx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              // Icon Pill
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: tx.iconBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tx.icon, color: tx.iconColor, size: 22),
                              ),
                              const SizedBox(width: 12),

                              // Description & Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx.id} · ${tx.formattedDate}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Amount & Status Badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tx.formattedAmount,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: tx.isCredit ? AppColors.greenLight : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
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

  Widget _buildTab(TransactionFilterTab tab, String label) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = tab);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D28D9) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purpleLight : AppColors.cardBorder,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
