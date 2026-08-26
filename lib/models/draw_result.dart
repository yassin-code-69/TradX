import 'package:flutter/material.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/theme/app_colors.dart';

class DrawResult {
  final String id;
  final String title;
  final String date;
  final List<String> winningNumbers;
  final DrawType type;
  final Color accentColor;

  const DrawResult({
    required this.id,
    required this.title,
    required this.date,
    required this.winningNumbers,
    required this.type,
    required this.accentColor,
  });

  static const List<DrawResult> latestResults = [
    DrawResult(
      id: 'res_1',
      title: 'Hourly Draw',
      date: '09:00 PM',
      winningNumbers: ['1', '7', '3'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
    ),
    DrawResult(
      id: 'res_2',
      title: 'Daily Draw',
      date: '10:00 PM',
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
  ];
}
