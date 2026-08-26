import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

enum DrawType { mega, daily, hourly }

class PrizeTier {
  final String tierName;
  final String matchRule;
  final String prizeAmount;
  final String winnerPercentageOrFixed;
  final Color badgeColor;

  const PrizeTier({
    required this.tierName,
    required this.matchRule,
    required this.prizeAmount,
    required this.winnerPercentageOrFixed,
    required this.badgeColor,
  });
}

class DrawModel {
  final String id;
  final String title;
  final String subtitle;
  final String prize;
  final String ticketPrice;
  final int unitPriceInt;
  final DrawType type;
  final bool isHot;
  final Color accentColor;
  final String scheduleInfo;
  final int totalDigits;
  final String nextDrawTime;
  final DateTime nextDrawDateTime;
  final List<PrizeTier> prizeTiers;
  final String drawRulesSummary;

  const DrawModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.prize,
    required this.ticketPrice,
    required this.unitPriceInt,
    required this.type,
    this.isHot = false,
    required this.accentColor,
    required this.scheduleInfo,
    required this.totalDigits,
    required this.nextDrawTime,
    required this.nextDrawDateTime,
    this.prizeTiers = const [],
    this.drawRulesSummary = '',
  });

  static List<DrawModel> sampleDraws = [
    DrawModel(
      id: 'mega',
      title: 'Mega Draw',
      subtitle: '1st of Every Month',
      prize: '৳ 5,00,000',
      ticketPrice: '৳ 100',
      unitPriceInt: 100,
      type: DrawType.mega,
      isHot: true,
      accentColor: AppColors.goldPrimary,
      scheduleInfo: '01 Sep 2026 | 09:00 PM',
      totalDigits: 7,
      nextDrawTime: '01 Sep 2026 | 09:00 PM',
      nextDrawDateTime: DateTime.now().add(const Duration(days: 5, hours: 21, minutes: 14)),
      drawRulesSummary: 'Match all 7 digits in exact order for 1st Prize Jackpot. 2nd and 3rd prizes for 6 and 5 digit matches.',
      prizeTiers: const [
        PrizeTier(
          tierName: '1st Prize (Jackpot)',
          matchRule: 'Match all 7 digits exactly (e.g. 7-7-7-7-7-7-7)',
          prizeAmount: '৳ 5,00,000',
          winnerPercentageOrFixed: 'Guaranteed 1 Winner',
          badgeColor: AppColors.goldPrimary,
        ),
        PrizeTier(
          tierName: '2nd Prize',
          matchRule: 'Match last 6 digits in sequence',
          prizeAmount: '৳ 1,00,000',
          winnerPercentageOrFixed: 'Guaranteed 2 Winners',
          badgeColor: Color(0xFFC084FC),
        ),
        PrizeTier(
          tierName: '3rd Prize',
          matchRule: 'Match last 5 digits in sequence',
          prizeAmount: '৳ 25,000',
          winnerPercentageOrFixed: '5 Winners',
          badgeColor: Color(0xFF38BDF8),
        ),
        PrizeTier(
          tierName: 'Consolation Prize',
          matchRule: 'Match first 4 or last 4 digits',
          prizeAmount: '৳ 2,500',
          winnerPercentageOrFixed: '20 Winners',
          badgeColor: Color(0xFF34D399),
        ),
      ],
    ),
    DrawModel(
      id: 'daily',
      title: 'Daily Draw',
      subtitle: 'Every Day 10:00 PM',
      prize: '৳ 50,000',
      ticketPrice: '৳ 60',
      unitPriceInt: 60,
      type: DrawType.daily,
      isHot: false,
      accentColor: AppColors.greenAccent,
      scheduleInfo: 'Today 10:00 PM',
      totalDigits: 3,
      nextDrawTime: '10:00 PM',
      nextDrawDateTime: DateTime.now().add(const Duration(hours: 4, minutes: 35)),
      drawRulesSummary: 'Select any 3 digits (000 to 999). Daily draw conducted at 10:00 PM every single evening.',
      prizeTiers: const [
        PrizeTier(
          tierName: '1st Prize (3-Digit Match)',
          matchRule: 'Match all 3 digits in exact sequence',
          prizeAmount: '৳ 50,000',
          winnerPercentageOrFixed: '100% Shared Jackpot',
          badgeColor: AppColors.greenAccent,
        ),
        PrizeTier(
          tierName: '2nd Prize (2-Digit Match)',
          matchRule: 'Match last 2 digits',
          prizeAmount: '৳ 2,500',
          winnerPercentageOrFixed: 'Fixed Payout',
          badgeColor: Color(0xFF38BDF8),
        ),
        PrizeTier(
          tierName: '3rd Prize (1-Digit Match)',
          matchRule: 'Match last digit',
          prizeAmount: '৳ 250',
          winnerPercentageOrFixed: 'Fixed Payout',
          badgeColor: Color(0xFFFBBF24),
        ),
      ],
    ),
    DrawModel(
      id: 'hourly',
      title: 'Hourly Draw',
      subtitle: 'Every Hour',
      prize: '৳ 20,000',
      ticketPrice: '৳ 20',
      unitPriceInt: 20,
      type: DrawType.hourly,
      isHot: false,
      accentColor: AppColors.purpleAccent,
      scheduleInfo: 'Every Hour',
      totalDigits: 3,
      nextDrawTime: '00:18:42',
      nextDrawDateTime: DateTime.now().add(const Duration(minutes: 18, seconds: 42)),
      drawRulesSummary: 'Rapid lottery draw every 60 minutes! Pick 3 numbers for instant winning opportunities 24/7.',
      prizeTiers: const [
        PrizeTier(
          tierName: '1st Prize (3-Digit Match)',
          matchRule: 'Match all 3 digits in exact sequence',
          prizeAmount: '৳ 20,000',
          winnerPercentageOrFixed: 'Instant Credit',
          badgeColor: AppColors.purpleAccent,
        ),
        PrizeTier(
          tierName: '2nd Prize (2-Digit Match)',
          matchRule: 'Match last 2 digits',
          prizeAmount: '৳ 1,000',
          winnerPercentageOrFixed: 'Instant Credit',
          badgeColor: Color(0xFFEC4899),
        ),
        PrizeTier(
          tierName: '3rd Prize (1-Digit Match)',
          matchRule: 'Match last digit',
          prizeAmount: '৳ 100',
          winnerPercentageOrFixed: 'Instant Credit',
          badgeColor: Color(0xFFF59E0B),
        ),
      ],
    ),
  ];
}
