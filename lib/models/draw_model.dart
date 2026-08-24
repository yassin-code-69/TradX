import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

enum DrawType { mega, daily, hourly }

class DrawModel {
  final String id;
  final String title;
  final String subtitle;
  final String prize;
  final String ticketPrice;
  final DrawType type;
  final bool isHot;
  final Color accentColor;
  final String scheduleInfo;
  final int totalDigits;
  final String nextDrawTime;

  const DrawModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.prize,
    required this.ticketPrice,
    required this.type,
    this.isHot = false,
    required this.accentColor,
    required this.scheduleInfo,
    required this.totalDigits,
    required this.nextDrawTime,
  });

  static const List<DrawModel> sampleDraws = [
    DrawModel(
      id: 'mega',
      title: 'Mega Draw',
      subtitle: '1st of Every Month',
      prize: '৳ 5,00,000',
      ticketPrice: '৳ 100',
      type: DrawType.mega,
      isHot: true,
      accentColor: AppColors.goldPrimary,
      scheduleInfo: '01 Sep 2026 | 09:00 PM',
      totalDigits: 7,
      nextDrawTime: '01 Sep 2026 | 09:00 PM',
    ),
    DrawModel(
      id: 'daily',
      title: 'Daily Draw',
      subtitle: 'Every Day 10:00 PM',
      prize: '৳ 50,000',
      ticketPrice: '৳ 60',
      type: DrawType.daily,
      isHot: false,
      accentColor: AppColors.greenAccent,
      scheduleInfo: 'Today 10:00 PM',
      totalDigits: 3,
      nextDrawTime: '10:00 PM',
    ),
    DrawModel(
      id: 'hourly',
      title: 'Hourly Draw',
      subtitle: 'Every Hour',
      prize: '৳ 20,000',
      ticketPrice: '৳ 20',
      type: DrawType.hourly,
      isHot: false,
      accentColor: AppColors.purpleAccent,
      scheduleInfo: 'Every Hour',
      totalDigits: 3,
      nextDrawTime: '00:18:42',
    ),
  ];
}
