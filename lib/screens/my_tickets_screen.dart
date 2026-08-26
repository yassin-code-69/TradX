import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/daily_draw_screen.dart';
import 'package:tradex/screens/hourly_draw_screen.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  DrawType _selectedFilter = DrawType.mega;
  final AppState _appState = AppState();

  static const List<Map<String, dynamic>> _sampleMegaTickets = [
    {
      'title': 'Mega Draw',
      'date': '01 Sep 2026 | 09:00 PM',
      'digits': ['1', '2', '3', '4', '6', '7'],
      'price': '৳ 100',
      'status': 'ACTIVE',
      'type': DrawType.mega,
    },
    {
      'title': 'Mega Draw',
      'date': '01 Sep 2026 | 09:00 PM',
      'digits': ['4', '5', '6', '7', '8', '0'],
      'price': '৳ 100',
      'status': 'ACTIVE',
      'type': DrawType.mega,
    },
    {
      'title': 'Mega Draw',
      'date': '01 Sep 2026 | 09:00 PM',
      'digits': ['7', '8', '9', '0', '2', '3'],
      'price': '৳ 100',
      'status': 'ACTIVE',
      'type': DrawType.mega,
    },
  ];

  static const List<Map<String, dynamic>> _sampleDailyTickets = [
    {
      'title': 'Daily Draw',
      'date': 'Today 10:00 PM',
      'digits': ['5', '6', '7'],
      'price': '৳ 60',
      'status': 'ACTIVE',
      'type': DrawType.daily,
    },
    {
      'title': 'Daily Draw',
      'date': 'Today 10:00 PM',
      'digits': ['2', '4', '9'],
      'price': '৳ 60',
      'status': 'ACTIVE',
      'type': DrawType.daily,
    },
  ];

  static const List<Map<String, dynamic>> _sampleHourlyTickets = [
    {
      'title': 'Hourly Draw',
      'date': 'Today 09:00 PM',
      'digits': ['1', '7', '3'],
      'price': '৳ 20',
      'status': 'ACTIVE',
      'type': DrawType.hourly,
    },
    {
      'title': 'Hourly Draw',
      'date': 'Today 09:00 PM',
      'digits': ['8', '2', '4'],
      'price': '৳ 20',
      'status': 'ACTIVE',
      'type': DrawType.hourly,
    },
  ];

  void _onBuyMoreTickets() {
    switch (_selectedFilter) {
      case DrawType.mega:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MegaDrawScreen()),
        );
        break;
      case DrawType.daily:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyDrawScreen()),
        );
        break;
      case DrawType.hourly:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HourlyDrawScreen()),
        );
        break;
    }
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
            const SizedBox(height: 12),
            // Filter Pills Row: [Hourly] [Daily] [Mega]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterTab('Hourly', DrawType.hourly),
                  const SizedBox(width: 10),
                  _buildFilterTab('Daily', DrawType.daily),
                  const SizedBox(width: 10),
                  _buildFilterTab('Mega', DrawType.mega),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tickets List
            Expanded(
              child: ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  final purchasedForFilter = _appState.purchasedTickets
                      .where((t) => t.draw.type == _selectedFilter)
                      .toList();

                  final sampleForFilter = _getSampleTicketsForFilter(_selectedFilter);

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // User's Real Purchased Tickets first (if any)
                      ...purchasedForFilter.map((ticket) {
                        final digits = ticket.number.split('');
                        final dateStr = DateFormat('dd MMM yyyy | hh:mm a').format(ticket.purchaseDate);
                        return _buildTicketCard(
                          title: ticket.draw.title,
                          date: dateStr,
                          digits: digits,
                          price: '৳ ${ticket.totalAmount}',
                          status: 'ACTIVE',
                          type: ticket.draw.type,
                        );
                      }),

                      // Sample tickets matching the design
                      ...sampleForFilter.map((ticket) {
                        return _buildTicketCard(
                          title: ticket['title'] as String,
                          date: ticket['date'] as String,
                          digits: List<String>.from(ticket['digits'] as List),
                          price: ticket['price'] as String,
                          status: ticket['status'] as String,
                          type: ticket['type'] as DrawType,
                        );
                      }),

                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),

            // Full-width Bottom Button: BUY MORE TICKETS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _onBuyMoreTickets,
                    child: Center(
                      child: Text(
                        'BUY MORE TICKETS',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleTicketsForFilter(DrawType type) {
    switch (type) {
      case DrawType.mega:
        return _sampleMegaTickets;
      case DrawType.daily:
        return _sampleDailyTickets;
      case DrawType.hourly:
        return _sampleHourlyTickets;
    }
  }

  Widget _buildFilterTab(String label, DrawType type) {
    final bool isSelected = _selectedFilter == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = type;
          });
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC107) : AppColors.pillBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFC107) : AppColors.pillBorder,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.black87 : const Color(0xFF8E95A5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard({
    required String title,
    required String date,
    required List<String> digits,
    required String price,
    required String status,
    required DrawType type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header: Icon + Title + Date + ACTIVE Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDrawIcon(type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.greenAccent.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Digits row + Price on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Digits
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: digits.map((digit) {
                    return Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161A29),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getAccentBorderColor(type),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        digit,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAccentBorderColor(DrawType type) {
    switch (type) {
      case DrawType.mega:
        return AppColors.goldPrimary.withValues(alpha: 0.5);
      case DrawType.daily:
        return AppColors.greenAccent.withValues(alpha: 0.5);
      case DrawType.hourly:
        return AppColors.purpleAccent.withValues(alpha: 0.5);
    }
  }

  Widget _buildDrawIcon(DrawType type) {
    switch (type) {
      case DrawType.mega:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2010),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldPrimary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.emoji_events_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
        );
      case DrawType.daily:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0C2B1D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.greenAccent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.confirmation_number_rounded,
              color: AppColors.greenLight,
              size: 20,
            ),
          ),
        );
      case DrawType.hourly:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF231538),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.purpleAccent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.purpleLight,
              size: 20,
            ),
          ),
        );
    }
  }
}
