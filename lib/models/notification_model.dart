import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

enum NotificationCategory {
  all,
  draws,
  winnings,
  wallet,
  system,
  promotions,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? deepLinkRoute;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.deepLinkRoute,
    this.data,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? deepLinkRoute,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
      data: data ?? this.data,
    );
  }

  IconData get icon {
    switch (category) {
      case NotificationCategory.draws:
        return Icons.confirmation_number_outlined;
      case NotificationCategory.winnings:
        return Icons.emoji_events_rounded;
      case NotificationCategory.wallet:
        return Icons.account_balance_wallet_outlined;
      case NotificationCategory.promotions:
        return Icons.local_offer_outlined;
      case NotificationCategory.system:
      case NotificationCategory.all:
        return Icons.notifications_active_outlined;
    }
  }

  Color get iconColor {
    switch (category) {
      case NotificationCategory.winnings:
        return AppColors.goldPrimary;
      case NotificationCategory.wallet:
        return AppColors.greenLight;
      case NotificationCategory.draws:
        return AppColors.purpleLight;
      case NotificationCategory.promotions:
        return AppColors.cyanAccent;
      case NotificationCategory.system:
      case NotificationCategory.all:
        return Colors.white70;
    }
  }

  Color get iconBg {
    switch (category) {
      case NotificationCategory.winnings:
        return const Color(0xFF2E2208);
      case NotificationCategory.wallet:
        return AppColors.greenBg;
      case NotificationCategory.draws:
        return AppColors.purpleBg;
      case NotificationCategory.promotions:
        return const Color(0xFF0F2535);
      case NotificationCategory.system:
      case NotificationCategory.all:
        return AppColors.cardBgElevated;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return difference.inMinutes <= 1 ? "Just now" : "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
