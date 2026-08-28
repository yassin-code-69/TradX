import 'package:flutter/material.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/theme/app_colors.dart';

class DrawResult {
  final String id;
  final String drawId;
  final String title;
  final String date;
  final DateTime? drawDateTime;
  final List<String> winningNumbers;
  final DrawType type;
  final Color accentColor;
  final String totalPrizeDistributed;
  final int totalWinnersCount;
  final String jackpotWinnerName;
  final List<PrizeTier> prizeBreakdowns;

  const DrawResult({
    required this.id,
    this.drawId = 'mega',
    required this.title,
    required this.date,
    this.drawDateTime,
    required this.winningNumbers,
    required this.type,
    required this.accentColor,
    this.totalPrizeDistributed = '৳ 50,000',
    this.totalWinnersCount = 142,
    this.jackpotWinnerName = 'Anonymous User (usr_8492)',
    this.prizeBreakdowns = const [],
  });

  DateTime get effectiveDrawDateTime => drawDateTime ?? DateTime.now();

  String get joinedWinningNumber => winningNumbers.join('');

  static List<DrawResult> latestResults = [
    DrawResult(
      id: 'res_hourly_latest',
      drawId: 'hourly',
      title: 'Hourly Draw',
      date: 'Today | 09:00 PM',
      drawDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      winningNumbers: ['1', '7', '3'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
      totalPrizeDistributed: '৳ 21,100',
      totalWinnersCount: 28,
      jackpotWinnerName: 'Rahim_99 (017***382)',
    ),
    DrawResult(
      id: 'res_daily_latest',
      drawId: 'daily',
      title: 'Daily Draw',
      date: 'Yesterday | 10:00 PM',
      drawDateTime: DateTime.now().subtract(const Duration(hours: 23)),
      winningNumbers: ['5', '6', '7'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
      totalPrizeDistributed: '৳ 52,750',
      totalWinnersCount: 64,
      jackpotWinnerName: 'Tanvir_Boss (019***991)',
    ),
    DrawResult(
      id: 'res_mega_latest',
      drawId: 'mega',
      title: 'Mega Draw #42',
      date: '01 Aug 09:00 PM',
      drawDateTime: DateTime(2026, 8, 1, 21, 0),
      winningNumbers: ['1', '2', '3', '4', '5', '6', '7'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
      totalPrizeDistributed: '৳ 6,25,000',
      totalWinnersCount: 189,
      jackpotWinnerName: 'Shek Ahmmed (017***678)',
    ),
    DrawResult(
      id: 'res_hourly_prev',
      drawId: 'hourly',
      title: 'Hourly Draw #1048',
      date: 'Today | 08:00 PM',
      drawDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      winningNumbers: ['9', '0', '4'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
      totalPrizeDistributed: '৳ 20,400',
      totalWinnersCount: 19,
      jackpotWinnerName: 'Fahim_Dhaka (018***442)',
    ),
    DrawResult(
      id: 'res_daily_prev',
      drawId: 'daily',
      title: 'Daily Draw #310',
      date: '15 Aug 2026 | 10:00 PM',
      drawDateTime: DateTime(2026, 8, 15, 22, 0),
      winningNumbers: ['3', '8', '2'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
      totalPrizeDistributed: '৳ 51,500',
      totalWinnersCount: 52,
      jackpotWinnerName: 'Mamun_Chy (016***112)',
    ),
  ];
}
