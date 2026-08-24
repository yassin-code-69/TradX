import 'package:flutter/material.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/transaction_history_screen.dart';
import 'package:tradex/theme/app_colors.dart';

class PurchasedTicket {
  final String id;
  final DrawModel draw;
  final String number;
  final int count;
  final int totalAmount;
  final DateTime purchaseDate;

  const PurchasedTicket({
    required this.id,
    required this.draw,
    required this.number,
    required this.count,
    required this.totalAmount,
    required this.purchaseDate,
  });
}

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  double _walletBalance = 2540.50;
  double get walletBalance => _walletBalance;

  String get formattedBalance {
    final parts = _walletBalance.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decimalPart';
  }

  double _totalAdded = 8500.00;
  double _totalWithdrawn = 3000.00;
  final double _winningAmount = 7000.00;
  double _usedForTickets = 9960.00;
  final double _bonus = 1000.00;

  double get totalAdded => _totalAdded;
  double get totalWithdrawn => _totalWithdrawn;
  double get winningAmount => _winningAmount;
  double get usedForTickets => _usedForTickets;
  double get bonus => _bonus;

  final List<TransactionItem> _transactions = [
    const TransactionItem(
      title: 'Add Money',
      date: '17 May 2026 | 11:20 AM',
      amount: '+ ৳ 1,000',
      isCredit: true,
      category: TxType.addMoney,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.greenLight,
      iconBg: AppColors.greenBg,
    ),
    const TransactionItem(
      title: 'Mega Draw Ticket',
      date: '17 May 2026 | 11:25 AM',
      amount: '- ৳ 100',
      isCredit: false,
      category: TxType.tickets,
      icon: Icons.emoji_events_outlined,
      iconColor: AppColors.purpleLight,
      iconBg: AppColors.purpleBg,
    ),
    const TransactionItem(
      title: 'Daily Draw Ticket',
      date: '17 May 2026 | 11:30 AM',
      amount: '- ৳ 60',
      isCredit: false,
      category: TxType.tickets,
      icon: Icons.confirmation_number_outlined,
      iconColor: Color(0xFFEF4444),
      iconBg: Color(0xFF2C1518),
    ),
    const TransactionItem(
      title: 'Hourly Draw Ticket',
      date: '17 May 2026 | 11:35 AM',
      amount: '- ৳ 20',
      isCredit: false,
      category: TxType.tickets,
      icon: Icons.access_time_rounded,
      iconColor: AppColors.cyanAccent,
      iconBg: Color(0xFF0F2535),
    ),
    const TransactionItem(
      title: 'Withdraw',
      date: '16 May 2026 | 08:05 PM',
      amount: '- ৳ 500',
      isCredit: false,
      category: TxType.withdraw,
      icon: Icons.lock_outline_rounded,
      iconColor: AppColors.greenAccent,
      iconBg: AppColors.greenBg,
    ),
    const TransactionItem(
      title: 'Add Money',
      date: '16 May 2026 | 07:30 PM',
      amount: '+ ৳ 500',
      isCredit: true,
      category: TxType.addMoney,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.greenLight,
      iconBg: AppColors.greenBg,
    ),
    const TransactionItem(
      title: 'Mega Draw Ticket',
      date: '16 May 2026 | 07:20 PM',
      amount: '- ৳ 100',
      isCredit: false,
      category: TxType.tickets,
      icon: Icons.confirmation_number_outlined,
      iconColor: Color(0xFFEF4444),
      iconBg: Color(0xFF2C1518),
    ),
  ];

  List<TransactionItem> get transactions => List.unmodifiable(_transactions);

  final List<PurchasedTicket> _purchasedTickets = [];
  List<PurchasedTicket> get purchasedTickets => List.unmodifiable(_purchasedTickets);

  // Add Money
  void addMoney(double amount, String method) {
    _walletBalance += amount;
    _totalAdded += amount;

    _transactions.insert(
      0,
      TransactionItem(
        title: 'Add Money ($method)',
        date: 'Today | Just now',
        amount: '+ ৳ ${amount.toStringAsFixed(0)}',
        isCredit: true,
        category: TxType.addMoney,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.greenLight,
        iconBg: AppColors.greenBg,
      ),
    );

    notifyListeners();
  }

  // Withdraw
  bool withdraw(double amount, String method) {
    if (amount > _walletBalance) {
      return false;
    }
    _walletBalance -= amount;
    _totalWithdrawn += amount;

    _transactions.insert(
      0,
      TransactionItem(
        title: 'Withdraw ($method)',
        date: 'Today | Just now',
        amount: '- ৳ ${amount.toStringAsFixed(0)}',
        isCredit: false,
        category: TxType.withdraw,
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.greenAccent,
        iconBg: AppColors.greenBg,
      ),
    );

    notifyListeners();
    return true;
  }

  // Buy Ticket
  bool buyTicket({
    required DrawModel draw,
    required String number,
    required int count,
    required int unitPrice,
  }) {
    final double total = (unitPrice * count).toDouble();
    if (total > _walletBalance) {
      return false;
    }

    _walletBalance -= total;
    _usedForTickets += total;

    _purchasedTickets.insert(
      0,
      PurchasedTicket(
        id: 'TKT-${DateTime.now().millisecondsSinceEpoch}',
        draw: draw,
        number: number,
        count: count,
        totalAmount: total.toInt(),
        purchaseDate: DateTime.now(),
      ),
    );

    _transactions.insert(
      0,
      TransactionItem(
        title: '${draw.title} Ticket ($number)',
        date: 'Today | Just now',
        amount: '- ৳ ${total.toInt()}',
        isCredit: false,
        category: TxType.tickets,
        icon: draw.type == DrawType.mega
            ? Icons.emoji_events_outlined
            : draw.type == DrawType.daily
                ? Icons.confirmation_number_outlined
                : Icons.access_time_rounded,
        iconColor: draw.accentColor,
        iconBg: draw.accentColor.withValues(alpha: 0.15),
      ),
    );

    notifyListeners();
    return true;
  }
}
