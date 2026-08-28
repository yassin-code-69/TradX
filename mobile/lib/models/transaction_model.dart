import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

enum TransactionType {
  deposit,
  withdraw,
  ticketPurchase,
  winning,
  transferSent,
  transferReceived,
  bonus,
  commission,
  refund,
}

enum TransactionStatus {
  pending,
  completed,
  approved,
  rejected,
  processing,
  failed,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final String title;
  final String description;
  final double amount;
  final double fee;
  final bool isCredit;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? method;
  final String? recipientOrSender;
  final String? relatedDrawTitle;
  final String? relatedTicketNumber;
  final String? proofImageUrl;
  final String? rejectReason;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    this.fee = 0.0,
    required this.isCredit,
    required this.timestamp,
    this.status = TransactionStatus.completed,
    this.method,
    this.recipientOrSender,
    this.relatedDrawTitle,
    this.relatedTicketNumber,
    this.proofImageUrl,
    this.rejectReason,
    this.note,
  });

  String get date => formattedDate;
  String get category => type.name;

  String get formattedAmount {
    final prefix = isCredit ? '+ ৳ ' : '- ৳ ';
    final parts = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    return '$prefix$parts';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return difference.inMinutes <= 1 ? "Just now" : "${difference.inMinutes} mins ago";
    } else if (difference.inHours < 24 && now.day == timestamp.day) {
      return 'Today | ${_formatTime(timestamp)}';
    } else if (difference.inDays < 2 && now.day - timestamp.day == 1) {
      return 'Yesterday | ${_formatTime(timestamp)}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${timestamp.day.toString().padLeft(2, '0')} ${months[timestamp.month - 1]} ${timestamp.year} | ${_formatTime(timestamp)}';
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  IconData get icon {
    switch (type) {
      case TransactionType.deposit:
        return Icons.account_balance_wallet_outlined;
      case TransactionType.withdraw:
        return Icons.lock_outline_rounded;
      case TransactionType.ticketPurchase:
        return Icons.confirmation_number_outlined;
      case TransactionType.winning:
        return Icons.emoji_events_outlined;
      case TransactionType.transferSent:
        return Icons.arrow_upward_rounded;
      case TransactionType.transferReceived:
        return Icons.arrow_downward_rounded;
      case TransactionType.bonus:
        return Icons.card_giftcard_rounded;
      case TransactionType.commission:
        return Icons.monetization_on_outlined;
      case TransactionType.refund:
        return Icons.replay_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case TransactionType.deposit:
      case TransactionType.winning:
      case TransactionType.transferReceived:
      case TransactionType.bonus:
      case TransactionType.commission:
      case TransactionType.refund:
        return AppColors.greenLight;
      case TransactionType.withdraw:
        return AppColors.orangeAccent;
      case TransactionType.ticketPurchase:
        return AppColors.purpleLight;
      case TransactionType.transferSent:
        return AppColors.cyanAccent;
    }
  }

  Color get iconBg {
    switch (type) {
      case TransactionType.deposit:
      case TransactionType.winning:
      case TransactionType.transferReceived:
      case TransactionType.bonus:
      case TransactionType.commission:
      case TransactionType.refund:
        return AppColors.greenBg;
      case TransactionType.withdraw:
        return const Color(0xFF2E170F);
      case TransactionType.ticketPurchase:
        return AppColors.purpleBg;
      case TransactionType.transferSent:
        return const Color(0xFF0C2433);
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.completed:
      case TransactionStatus.approved:
        return AppColors.greenLight;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return AppColors.goldPrimary;
      case TransactionStatus.rejected:
      case TransactionStatus.failed:
        return AppColors.redAccent;
    }
  }
}
