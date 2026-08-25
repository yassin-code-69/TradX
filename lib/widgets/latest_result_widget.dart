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
              'LATEST RESULTS',
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
                    color: AppColors.goldAccent,
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
    return GestureDetector(
      onTap: onResultTap != null ? () => onResultTap!(result) : onSeeAllTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

            const SizedBox(width: 10),

            // Title & Date
            Expanded(
              child: Text(
                '${result.title}  ${result.date}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFC7CCD9),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Winning Digits Badges in Circles
            Row(
              mainAxisSize: MainAxisSize.min,
              children: result.winningNumbers.map((digit) {
                final isMega = result.type == DrawType.mega;
                final size = isMega ? 22.0 : 26.0;
                final fontSize = isMega ? 10.5 : 12.5;

                Color circleBg;
                Color circleBorder;

                switch (result.type) {
                  case DrawType.hourly:
                    circleBg = const Color(0xFF2B1545);
                    circleBorder = AppColors.purpleAccent;
                    break;
                  case DrawType.daily:
                    circleBg = const Color(0xFF0C2B1D);
                    circleBorder = AppColors.greenAccent;
                    break;
                  case DrawType.mega:
                    circleBg = const Color(0xFF2A2010);
                    circleBorder = AppColors.goldPrimary;
                    break;
                }

                return Container(
                  margin: EdgeInsets.only(left: isMega ? 3 : 4),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: circleBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: circleBorder.withValues(alpha: 0.25),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIcon(DrawType type) {
    switch (type) {
      case DrawType.hourly:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.purpleBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.purpleAccent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: AppColors.purpleLight,
            size: 14,
          ),
        );
      case DrawType.daily:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.greenBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.greenLight,
            size: 14,
          ),
        );
      case DrawType.mega:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2010),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.goldAccent,
            size: 14,
          ),
        );
    }
  }
}
