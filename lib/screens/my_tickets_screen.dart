import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/ticket_model.dart';
import 'package:tradex/screens/daily_draw_screen.dart';
import 'package:tradex/screens/hourly_draw_screen.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

enum TicketFilterStatus { all, active, won, completed, lost }

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final AppState _appState = AppState();
  TicketFilterStatus _selectedStatusFilter = TicketFilterStatus.all;
  String _selectedDrawTypeFilter = 'all'; // 'all', 'mega', 'daily', 'hourly'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBuyTicketPressed() {
    HapticFeedback.selectionClick();
    if (_selectedDrawTypeFilter == 'daily') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyDrawScreen()));
    } else if (_selectedDrawTypeFilter == 'hourly') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HourlyDrawScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MegaDrawScreen()));
    }
  }

  void _showTicketReceiptModal(TicketModel ticket) {
    HapticFeedback.mediumImpact();
    final digits = ticket.number.split('');
    final formattedTime =
        '${ticket.purchaseDate.day.toString().padLeft(2, '0')}/${ticket.purchaseDate.month.toString().padLeft(2, '0')}/${ticket.purchaseDate.year} '
        '${ticket.purchaseDate.hour > 12 ? ticket.purchaseDate.hour - 12 : (ticket.purchaseDate.hour == 0 ? 12 : ticket.purchaseDate.hour)}:'
        '${ticket.purchaseDate.minute.toString().padLeft(2, '0')} ${ticket.purchaseDate.hour >= 12 ? 'PM' : 'AM'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: const BoxDecoration(
            color: AppColors.cardBgElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Handle
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorderHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket Receipt Details',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TradexStatusChip(
                    label: ticket.statusLabel,
                    color: ticket.statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Receipt Body
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    // Copyable Serial
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TICKET SERIAL ID',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                ticket.ticketNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: ticket.ticketNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ticket Serial ID copied!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Number Pills
                    Text(
                      'LUCKY COMBINATION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: digits.map((d) {
                        return Container(
                          width: digits.length > 5 ? 32 : 40,
                          height: digits.length > 5 ? 36 : 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardBgElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ticket.draw.accentColor, width: 1.4),
                          ),
                          child: Text(
                            d,
                            style: GoogleFonts.poppins(
                              fontSize: digits.length > 5 ? 16 : 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),

                    _buildModalDetailRow('Draw Title', ticket.draw.title),
                    _buildModalDetailRow('Quantity', '${ticket.count} Ticket(s)'),
                    _buildModalDetailRow('Unit Price', '৳ ${ticket.unitPrice}'),
                    _buildModalDetailRow('Total Paid', '৳ ${ticket.totalAmount}'),
                    _buildModalDetailRow('Draw Date', ticket.draw.scheduleInfo),
                    _buildModalDetailRow('Purchase Time', formattedTime),
                    if (ticket.isWon)
                      _buildModalDetailRow(
                        'Winning Prize',
                        '৳ ${ticket.winningAmount.toStringAsFixed(0)}',
                        highlightColor: AppColors.greenLight,
                      ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),

                    // Barcode Simulator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TRADEX VERIFIED ENTRY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenLight,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            12,
                            (i) => Container(
                              margin: const EdgeInsets.only(left: 2),
                              width: (i % 3 == 0) ? 3 : 1.5,
                              height: 18,
                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TradexButton(
                      text: 'Share Ticket',
                      variant: TradexButtonVariant.outline,
                      icon: Icons.share_rounded,
                      height: 44,
                      fontSize: 13,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: '🎟️ My Tradex Ticket: ${ticket.draw.title} (${ticket.number})\n'
                                'Serial ID: ${ticket.ticketNumber}\n'
                                'Draw Schedule: ${ticket.draw.scheduleInfo}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket details copied for sharing!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TradexButton(
                      text: 'Close',
                      variant: TradexButtonVariant.glass,
                      height: 44,
                      fontSize: 13,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: highlightColor ?? Colors.white,
            ),
          ),
        ],
      ),
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _appState.setTabIndex(0);
            }
          },
        ),
        title: Text(
          'My Tickets',
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
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by Ticket ID (e.g. TX-948) or Number...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ),

            // 2. Draw Type Filter Chips (All, Mega, Daily, Hourly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDrawTypeFilterChip('All Draws', 'all', Icons.all_inclusive_rounded),
                    const SizedBox(width: 8),
                    _buildDrawTypeFilterChip('👑 Mega Draw', 'mega', Icons.emoji_events_rounded),
                    const SizedBox(width: 8),
                    _buildDrawTypeFilterChip('🎟️ Daily Draw', 'daily', Icons.confirmation_number_rounded),
                    const SizedBox(width: 8),
                    _buildDrawTypeFilterChip('⚡ Hourly Draw', 'hourly', Icons.access_time_rounded),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. Status Filter Tabs (All, Active, Won, Completed, Lost)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildStatusTab('All', TicketFilterStatus.all),
                    _buildStatusTab('Active', TicketFilterStatus.active),
                    _buildStatusTab('Won 🏆', TicketFilterStatus.won),
                    _buildStatusTab('Unmatched', TicketFilterStatus.lost),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Ticket Cards List (Reactive to AppState)
            Expanded(
              child: ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  final allTickets = _appState.tickets;

                  // Filter by draw type
                  final typeFiltered = _selectedDrawTypeFilter == 'all'
                      ? allTickets
                      : allTickets.where((t) => t.draw.id == _selectedDrawTypeFilter).toList();

                  // Filter by status
                  final statusFiltered = typeFiltered.where((t) {
                    switch (_selectedStatusFilter) {
                      case TicketFilterStatus.all:
                        return true;
                      case TicketFilterStatus.active:
                        return t.isActive;
                      case TicketFilterStatus.won:
                        return t.isWon;
                      case TicketFilterStatus.completed:
                        return !t.isActive;
                      case TicketFilterStatus.lost:
                        return t.isLost;
                    }
                  }).toList();

                  // Filter by search query
                  final displayList = _searchQuery.isEmpty
                      ? statusFiltered
                      : statusFiltered.where((t) {
                          return t.ticketNumber.toLowerCase().contains(_searchQuery) ||
                              t.number.contains(_searchQuery) ||
                              t.draw.title.toLowerCase().contains(_searchQuery);
                        }).toList();

                  if (displayList.isEmpty) {
                    return TradexEmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title: 'No Tickets Found',
                      message: _searchQuery.isNotEmpty
                          ? 'No tickets match your search "$_searchQuery".'
                          : 'You have no tickets in this category yet. Pick your lucky numbers now!',
                      buttonText: 'BUY TICKET NOW',
                      onButtonPressed: _onBuyTicketPressed,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayList.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ticket = displayList[index];
                      return _buildRichTicketCard(ticket);
                    },
                  );
                },
              ),
            ),

            // 5. Bottom Quick CTA Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: TradexButton(
                text: 'BUY MORE TICKETS',
                variant: TradexButtonVariant.primaryGold,
                height: 48,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                onPressed: _onBuyTicketPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawTypeFilterChip(String label, String value, IconData icon) {
    final bool isSelected = _selectedDrawTypeFilter == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDrawTypeFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.18) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.goldPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(String label, TicketFilterStatus status) {
    final bool isSelected = _selectedStatusFilter == status;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedStatusFilter = status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.goldPrimary, width: 1) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichTicketCard(TicketModel ticket) {
    final digits = ticket.number.split('');
    final formattedDate =
        '${ticket.purchaseDate.day.toString().padLeft(2, '0')}/${ticket.purchaseDate.month.toString().padLeft(2, '0')} '
        '${ticket.purchaseDate.hour > 12 ? ticket.purchaseDate.hour - 12 : (ticket.purchaseDate.hour == 0 ? 12 : ticket.purchaseDate.hour)}:'
        '${ticket.purchaseDate.minute.toString().padLeft(2, '0')} ${ticket.purchaseDate.hour >= 12 ? 'PM' : 'AM'}';

    return GestureDetector(
      onTap: () => _showTicketReceiptModal(ticket),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ticket.isWon
                ? AppColors.greenAccent.withValues(alpha: 0.6)
                : AppColors.cardBorder,
            width: ticket.isWon ? 1.4 : 1,
          ),
          boxShadow: ticket.isWon
              ? [
                  BoxShadow(
                    color: AppColors.greenAccent.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Draw Icon + Title + Serial ID + Status Chip
            Row(
              children: [
                _buildDrawIcon(ticket.draw.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.draw.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${ticket.count} tkt)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${ticket.ticketNumber} • $formattedDate',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TradexStatusChip(
                  label: ticket.statusLabel,
                  color: ticket.statusColor,
                  fontSize: 9.5,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Number Pills & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Digit pills
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: digits.map((d) {
                      return Container(
                        width: digits.length > 5 ? 28 : 34,
                        height: digits.length > 5 ? 28 : 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardBgElevated,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ticket.draw.accentColor.withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          d,
                          style: GoogleFonts.poppins(
                            fontSize: digits.length > 5 ? 12 : 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '৳ ${ticket.totalAmount}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            // Special Winning Banner if Won
            if (ticket.isWon) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.greenAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.greenLight, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '🎉 Won Prize: ৳ ${ticket.winningAmount.toStringAsFixed(0)} (Credited to Wallet)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawIcon(DrawType type) {
    switch (type) {
      case DrawType.mega:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2010),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.emoji_events_rounded, color: AppColors.goldAccent, size: 18),
        );
      case DrawType.daily:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0C2B1D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.confirmation_number_rounded, color: AppColors.greenLight, size: 18),
        );
      case DrawType.hourly:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF231538),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.purpleAccent.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.access_time_filled_rounded, color: AppColors.purpleLight, size: 18),
        );
    }
  }
}
