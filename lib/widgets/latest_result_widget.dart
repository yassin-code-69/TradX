import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/theme/app_colors.dart';

class LatestResultsSection extends StatelessWidget {
  final List<DrawResult> results;
  final VoidCallback onSeeAllTap;
  final Function(DrawResult)? onResultTap;

  const LatestResultsSection({
    super.key,
    required this.results,
    required this.onSeeAllTap,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LATEST RESULT',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Result Cards
        ...results.map((result) => _buildResultRow(context, result)),
      ],
    );
  }

  Widget _buildResultRow(BuildContext context, DrawResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Small Type Icon
          _buildSmallIcon(result.type),

          const SizedBox(width: 8),

          // Title & Date
          Expanded(
            child: Text(
              '${result.title}  ${result.date}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFC7CCD9),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Winning Digits Badges
          Row(
            mainAxisSize: MainAxisSize.min,
            children: result.winningNumbers.map((digit) {
              return Container(
                margin: const EdgeInsets.only(left: 3),
                width: result.winningNumbers.length > 4 ? 20 : 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.pillBg,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.pillBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  digit,
                  style: GoogleFonts.inter(
                    fontSize: result.winningNumbers.length > 4 ? 11 : 12.5,
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
  }

  Widget _buildSmallIcon(DrawType type) {
    switch (type) {
      case DrawType.hourly:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.purpleBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.purpleAccent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: AppColors.purpleLight,
            size: 13,
          ),
        );
      case DrawType.daily:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.greenBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.greenLight,
            size: 13,
          ),
        );
      case DrawType.mega:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2010),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.goldAccent,
            size: 13,
          ),
        );
    }
  }
}
