import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/screens/all_results_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  DrawType _selectedFilter = DrawType.hourly;

  static const List<DrawResult> _allResults = [
    DrawResult(
      id: 'res_1',
      title: 'Hourly Draw',
      date: 'Today 09:00 PM',
      winningNumbers: ['1', '7', '3'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_2',
      title: 'Daily Draw',
      date: 'Today 10:00 PM',
      winningNumbers: ['5', '6', '7'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
    ),
    DrawResult(
      id: 'res_3',
      title: 'Mega Draw',
      date: '01 Aug 09:00 PM',
      winningNumbers: ['1', '2', '3', '4', '5', '6', '7'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
    ),
    DrawResult(
      id: 'res_4',
      title: 'Hourly Draw',
      date: 'Today 08:00 PM',
      winningNumbers: ['8', '2', '4'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_5',
      title: 'Hourly Draw',
      date: 'Today 07:00 PM',
      winningNumbers: ['4', '9', '0'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_6',
      title: 'Daily Draw',
      date: 'Yesterday 10:00 PM',
      winningNumbers: ['2', '4', '9'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
    ),
    DrawResult(
      id: 'res_7',
      title: 'Mega Draw',
      date: '01 Jul 09:00 PM',
      winningNumbers: ['7', '5', '9', '0', '3', '1', '8'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Show either the mock's curated 3 overview cards (hourly, daily, mega) or filtered by selected tab
    final List<DrawResult> displayedResults;
    if (_selectedFilter == DrawType.hourly) {
      // By default matches Screen 6 which showcases the 3 main cards
      displayedResults = [
        _allResults[0], // Hourly
        _allResults[1], // Daily
        _allResults[2], // Mega
      ];
    } else {
      displayedResults = _allResults.where((r) => r.type == _selectedFilter).toList();
    }

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
              AppState().setTabIndex(0);
            }
          },
        ),
        title: Text(
          'Results',
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

            // Filter Tabs: [ Hourly Results ] [ Daily Results ] [ Mega Results ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterPill('Hourly Results', DrawType.hourly),
                  const SizedBox(width: 8),
                  _buildFilterPill('Daily Results', DrawType.daily),
                  const SizedBox(width: 8),
                  _buildFilterPill('Mega Results', DrawType.mega),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Result Cards List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayedResults.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final result = displayedResults[index];
                  return _buildResultCard(result);
                },
              ),
            ),

            // Full-width Bottom Button: VIEW ALL RESULTS
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllResultsScreen()),
                      );
                    },
                    child: Center(
                      child: Text(
                        'VIEW ALL RESULTS',
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

  Widget _buildFilterPill(String label, DrawType type) {
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
            color: isSelected ? const Color(0xFF8B5CF6) : AppColors.pillBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B5CF6) : AppColors.pillBorder,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF8E95A5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(DrawResult result) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Date Header
          Text(
            result.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            result.date,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Digits Circles
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: result.winningNumbers.map((digit) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCircleBgColor(result.type),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getCircleBorderColor(result.type),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  digit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getCircleBgColor(DrawType type) {
    switch (type) {
      case DrawType.hourly:
        return const Color(0xFF231538);
      case DrawType.daily:
        return const Color(0xFF0C2B1D);
      case DrawType.mega:
        return const Color(0xFF2A2010);
    }
  }

  Color _getCircleBorderColor(DrawType type) {
    switch (type) {
      case DrawType.hourly:
        return const Color(0xFFA855F7);
      case DrawType.daily:
        return const Color(0xFF10B981);
      case DrawType.mega:
        return const Color(0xFFF59E0B);
    }
  }
}
