import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/theme/app_colors.dart';

class AllResultsScreen extends StatelessWidget {
  const AllResultsScreen({super.key});

  static const List<DrawResult> extendedResults = [
    DrawResult(
      id: 'res_1',
      title: 'Hourly Draw',
      date: '17 May, 08:00 PM',
      winningNumbers: ['1', '7', '3'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_2',
      title: 'Daily Draw',
      date: '17 May, 10:00 PM',
      winningNumbers: ['5', '6', '7'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
    ),
    DrawResult(
      id: 'res_3',
      title: 'Mega Draw',
      date: '01 May, 09:00 PM',
      winningNumbers: ['1', '2', '3', '4', '5', '6', '7'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
    ),
    DrawResult(
      id: 'res_4',
      title: 'Hourly Draw',
      date: '17 May, 07:00 PM',
      winningNumbers: ['8', '2', '4'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_5',
      title: 'Hourly Draw',
      date: '17 May, 06:00 PM',
      winningNumbers: ['3', '9', '0'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_6',
      title: 'Daily Draw',
      date: '16 May, 10:00 PM',
      winningNumbers: ['2', '4', '9'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
    ),
    DrawResult(
      id: 'res_7',
      title: 'Mega Draw',
      date: '01 Apr 2026, 09:00 PM',
      winningNumbers: ['7', '5', '9', '0', '3', '1', '8'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
    ),
  ];

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
          'Draw Results',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: extendedResults.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final result = extendedResults[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  _buildSmallIcon(result.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.date,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: result.winningNumbers.map((digit) {
                      return Container(
                        margin: const EdgeInsets.only(left: 3),
                        width: result.winningNumbers.length > 4 ? 20 : 24,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.pillBg,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.pillBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: GoogleFonts.inter(
                            fontSize: result.winningNumbers.length > 4 ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmallIcon(DrawType type) {
    switch (type) {
      case DrawType.hourly:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.purpleBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.purpleAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: AppColors.purpleLight,
            size: 16,
          ),
        );
      case DrawType.daily:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.greenBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.greenAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.greenLight,
            size: 16,
          ),
        );
      case DrawType.mega:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2010),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.goldPrimary.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.goldAccent,
            size: 16,
          ),
        );
    }
  }
}
