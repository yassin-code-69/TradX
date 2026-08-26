import 'package:flutter/material.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/theme/app_colors.dart';

enum TicketStatus {
  active,
  won,
  lost,
  pendingDraw,
  cancelled,
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final DrawModel draw;
  final String number;
  final int count;
  final int unitPrice;
  final int totalAmount;
  final DateTime purchaseDate;
  final DateTime drawDate;
  final TicketStatus status;
  final double winningAmount;
  final String transactionId;
  final int matchedDigitsCount;

  const TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.draw,
    required this.number,
    required this.count,
    required this.unitPrice,
    required this.totalAmount,
    required this.purchaseDate,
    required this.drawDate,
    this.status = TicketStatus.active,
    this.winningAmount = 0.0,
    required this.transactionId,
    this.matchedDigitsCount = 0,
  });

  bool get isWon => status == TicketStatus.won;
  bool get isActive => status == TicketStatus.active || status == TicketStatus.pendingDraw;
  bool get isLost => status == TicketStatus.lost;

  String get statusLabel {
    switch (status) {
      case TicketStatus.active:
      case TicketStatus.pendingDraw:
        return 'ACTIVE';
      case TicketStatus.won:
        return 'WON';
      case TicketStatus.lost:
        return 'UNMATCHED';
      case TicketStatus.cancelled:
        return 'REFUNDED';
    }
  }

  Color get statusColor {
    switch (status) {
      case TicketStatus.active:
      case TicketStatus.pendingDraw:
        return AppColors.goldPrimary;
      case TicketStatus.won:
        return AppColors.greenAccent;
      case TicketStatus.lost:
        return AppColors.textMuted;
      case TicketStatus.cancelled:
        return AppColors.redAccent;
    }
  }
}
