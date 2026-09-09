import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/models/kyc_model.dart';
import 'package:tradex/models/notification_model.dart';
import 'package:tradex/models/payment_method_model.dart';
import 'package:tradex/models/ticket_model.dart';
import 'package:tradex/models/transaction_model.dart';
import 'package:tradex/models/user_model.dart';
import 'package:tradex/services/api_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _initializeAuthListener();
    _initializeData();
  }

  bool get _isSupabaseInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _initializeAuthListener() {
    if (!_isSupabaseInitialized) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _isLoggedIn = true;
        ApiService().setAuthToken(session.accessToken);
        syncUserProfile();
      } else {
        _isLoggedIn = false;
      }

      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          _isLoggedIn = true;
          ApiService().setAuthToken(session.accessToken);
          syncUserProfile();
        } else {
          _isLoggedIn = false;
          ApiService().setAuthToken('');
          _currentUser = UserModel(
            id: '',
            fullName: 'Guest User',
            username: 'guest',
            email: '',
            phone: '',
            referralCode: '',
            joinedAt: DateTime.now(),
            kycStatus: KycStatus.notSubmitted,
            tier: 'Standard Member',
            referralCount: 0,
            referralEarnings: 0.0,
            isEmailVerified: false,
            isPhoneVerified: false,
            twoFactorEnabled: false,
            biometricsEnabled: false,
          );
          _kyc = const KycModel(status: KycStatus.notSubmitted);
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  // --- NAVIGATION TAB STATE ---
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  // --- USER & AUTH STATE ---
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  UserModel _currentUser = UserModel(
    id: '',
    fullName: 'Guest User',
    username: 'guest',
    email: '',
    phone: '',
    referralCode: '',
    joinedAt: DateTime.now(),
    kycStatus: KycStatus.notSubmitted,
    tier: 'Standard Member',
    referralCount: 0,
    referralEarnings: 0.0,
    isEmailVerified: false,
    isPhoneVerified: false,
    twoFactorEnabled: false,
    biometricsEnabled: false,
  );
  UserModel get currentUser => _currentUser;

  KycModel _kyc = const KycModel(
    status: KycStatus.notSubmitted,
  );
  KycModel get kyc => _kyc;

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    if (!_isSupabaseInitialized) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    final clean = emailOrPhone.trim();
    final isEmail = clean.contains('@');
    final AuthResponse response;
    if (isEmail) {
      response = await Supabase.instance.client.auth.signInWithPassword(
        email: clean,
        password: password,
      );
    } else {
      final phone = clean.startsWith('+')
          ? clean
          : (clean.startsWith('880')
              ? '+$clean'
              : '+880${clean.replaceFirst(RegExp(r'^0+'), '')}');
      response = await Supabase.instance.client.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
    }

    if (response.user != null) {
      _isLoggedIn = true;
      if (response.session != null) {
        ApiService().setAuthToken(response.session!.accessToken);
      }
      await syncUserProfile();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    if (!_isSupabaseInitialized) {
      _isLoggedIn = true;
      _currentUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        username: username,
        email: email,
        phone: phone,
        referralCode: referralCode ?? 'TRADEX',
        joinedAt: DateTime.now(),
        kycStatus: KycStatus.notSubmitted,
        tier: 'Standard Member',
      );
      notifyListeners();
      return true;
    }
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();
    final response = await Supabase.instance.client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': fullName.trim(),
        'username': username.trim(),
        'phone': cleanPhone,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referral_code': referralCode.trim(),
      },
    );

    if (response.user != null) {
      _isLoggedIn = response.session != null;
      if (response.session != null) {
        ApiService().setAuthToken(response.session!.accessToken);
      }
      await syncUserProfile();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    if (_isSupabaseInitialized) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    _isLoggedIn = false;
    ApiService().setAuthToken('');
    _currentUser = UserModel(
      id: '',
      fullName: 'Guest User',
      username: 'guest',
      email: '',
      phone: '',
      referralCode: '',
      joinedAt: DateTime.now(),
      kycStatus: KycStatus.notSubmitted,
      tier: 'Standard Member',
      referralCount: 0,
      referralEarnings: 0.0,
      isEmailVerified: false,
      isPhoneVerified: false,
      twoFactorEnabled: false,
      biometricsEnabled: false,
    );
    _kyc = const KycModel(status: KycStatus.notSubmitted);
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_isSupabaseInitialized) return;
    await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<bool> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.recovery,
  }) async {
    if (!_isSupabaseInitialized) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    final clean = email.trim();
    final isEmail = clean.contains('@');
    final AuthResponse response;
    if (isEmail) {
      response = await Supabase.instance.client.auth.verifyOTP(
        email: clean,
        token: token.trim(),
        type: type,
      );
    } else {
      final phone = clean.startsWith('+')
          ? clean
          : (clean.startsWith('880')
              ? '+$clean'
              : '+880${clean.replaceFirst(RegExp(r'^0+'), '')}');
      response = await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: token.trim(),
        type: OtpType.sms,
      );
    }

    if (response.user != null) {
      _isLoggedIn = response.session != null;
      if (response.session != null) {
        ApiService().setAuthToken(response.session!.accessToken);
      }
      await syncUserProfile();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> syncUserProfile() async {
    if (!_isSupabaseInitialized) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      final walletData = await Supabase.instance.client
          .from('wallets')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (profileData != null) {
        final kycStr =
            (profileData['kyc_status'] as String?)?.toUpperCase() ??
                'NOT_SUBMITTED';
        KycStatus kycStatus = KycStatus.notSubmitted;
        if (kycStr == 'VERIFIED') {
          kycStatus = KycStatus.verified;
        } else if (kycStr == 'PENDING') {
          kycStatus = KycStatus.pending;
        } else if (kycStr == 'REJECTED') {
          kycStatus = KycStatus.rejected;
        }

        _kyc = KycModel(
          status: kycStatus,
          fullName: profileData['full_name'] as String? ?? '',
        );

        _currentUser = UserModel(
          id: user.id,
          fullName: (profileData['full_name'] as String?) ??
              (user.userMetadata?['full_name'] as String?) ??
              '',
          username: (profileData['username'] as String?) ??
              (user.userMetadata?['username'] as String?) ??
              '',
          email: (profileData['email'] as String?) ?? user.email ?? '',
          phone: (profileData['phone'] as String?) ??
              user.phone ??
              (user.userMetadata?['phone'] as String?) ??
              '',
          avatarUrl: (profileData['avatar_url'] as String?) ?? '',
          country: (profileData['country'] as String?) ?? 'Bangladesh',
          referralCode: (profileData['referral_code'] as String?) ??
              (user.userMetadata?['referral_code'] as String?) ??
              'TRADEX',
          referralCount: (profileData['referral_count'] as num?)?.toInt() ?? 0,
          referralEarnings:
              ((profileData['referral_earnings'] as num?)?.toDouble()) ?? 0.0,
          kycStatus: kycStatus,
          tier: (profileData['tier'] as String?) ?? 'Standard Member',
          joinedAt: profileData['created_at'] != null
              ? DateTime.tryParse(profileData['created_at'] as String) ??
                  DateTime.now()
              : DateTime.now(),
          isEmailVerified: user.emailConfirmedAt != null,
          isPhoneVerified: user.phoneConfirmedAt != null,
          twoFactorEnabled: _currentUser.twoFactorEnabled,
          biometricsEnabled: _currentUser.biometricsEnabled,
        );
      } else {
        _currentUser = UserModel(
          id: user.id,
          fullName: (user.userMetadata?['full_name'] as String?) ?? '',
          username: (user.userMetadata?['username'] as String?) ?? '',
          email: user.email ?? '',
          phone: user.phone ??
              (user.userMetadata?['phone'] as String?) ??
              '',
          referralCode:
              (user.userMetadata?['referral_code'] as String?) ?? 'TRADEX',
          joinedAt: DateTime.now(),
          kycStatus: KycStatus.notSubmitted,
          tier: 'Standard Member',
        );
      }

      if (walletData != null) {
        final availMinor =
            (walletData['available_balance_minor'] as num?)?.toDouble() ?? 0.0;
        _walletBalance = availMinor / 100.0;
      }
    } catch (_) {
      _currentUser = UserModel(
        id: user.id,
        fullName: (user.userMetadata?['full_name'] as String?) ?? '',
        username: (user.userMetadata?['username'] as String?) ?? '',
        email: user.email ?? '',
        phone: user.phone ??
            (user.userMetadata?['phone'] as String?) ??
            '',
        referralCode:
            (user.userMetadata?['referral_code'] as String?) ?? 'TRADEX',
        joinedAt: DateTime.now(),
        kycStatus: KycStatus.notSubmitted,
        tier: 'Standard Member',
      );
    }
    notifyListeners();
  }

  void updateProfile({
    required String fullName,
    required String phone,
    required String email,
    String? avatarUrl,
  }) {
    _currentUser = _currentUser.copyWith(
      fullName: fullName,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
  }

  void submitKyc({
    required DocumentType documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    String? frontImageUrl,
    String? backImageUrl,
    String? selfieImageUrl,
  }) {
    _kyc = KycModel(
      status: KycStatus.pending,
      documentType: documentType,
      documentNumber: documentNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      frontImageUrl: frontImageUrl,
      backImageUrl: backImageUrl,
      selfieImageUrl: selfieImageUrl,
      submittedAt: DateTime.now(),
    );
    _currentUser = _currentUser.copyWith(kycStatus: KycStatus.pending);
    notifyListeners();
  }

  // --- WALLET STATE ---
  double _walletBalance = 2540.50;
  double get walletBalance => _walletBalance;

  final double _lockedBalance = 500.00; // Reserved for pending withdrawal
  double get lockedBalance => _lockedBalance;

  double get availableBalance => (_walletBalance - _lockedBalance).clamp(0.0, double.infinity);

  String get formattedBalance => _formatCurrency(_walletBalance);
  String get formattedAvailableBalance => _formatCurrency(availableBalance);
  String get formattedLockedBalance => _formatCurrency(_lockedBalance);

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

  static String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decimalPart';
  }

  // --- TICKETS & TRANSACTIONS STATE ---
  final List<TicketModel> _tickets = [];
  List<TicketModel> get tickets => List.unmodifiable(_tickets);
  List<TicketModel> get purchasedTickets => List.unmodifiable(_tickets);

  final List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  // Helper alias for Add Money
  void addMoney(double amount, String method) {
    addMoneyDepositRequest(
      providerName: method,
      amount: amount,
      senderAccount: _currentUser.phone,
      transactionId: 'TRX-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Helper alias for Withdraw
  bool withdraw(double amount, String method) {
    return withdrawMoney(
      providerName: method,
      amount: amount,
      receiverAccount: _currentUser.phone,
    ) != null;
  }


  // --- SAVED PAYMENT METHODS ---
  final List<PaymentMethodModel> _savedPaymentMethods = [];
  List<PaymentMethodModel> get savedPaymentMethods => List.unmodifiable(_savedPaymentMethods);

  // --- NOTIFICATIONS STATE ---
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  // --- APP SETTINGS ---
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  String _selectedLanguage = 'English';
  bool _drawRemindersEnabled = true;
  bool _winningAlertsEnabled = true;
  bool _walletAlertsEnabled = true;
  bool _promotionsEnabled = true;
  bool _securityAlertsEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  String get selectedLanguage => _selectedLanguage;
  bool get drawRemindersEnabled => _drawRemindersEnabled;
  bool get winningAlertsEnabled => _winningAlertsEnabled;
  bool get walletAlertsEnabled => _walletAlertsEnabled;
  bool get promotionsEnabled => _promotionsEnabled;
  bool get securityAlertsEnabled => _securityAlertsEnabled;

  void toggleSound(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }

  void toggleHaptics(bool value) {
    _hapticsEnabled = value;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void toggleDrawReminders(bool val) {
    _drawRemindersEnabled = val;
    notifyListeners();
  }

  void toggleWinningAlerts(bool val) {
    _winningAlertsEnabled = val;
    notifyListeners();
  }

  void toggleWalletAlerts(bool val) {
    _walletAlertsEnabled = val;
    notifyListeners();
  }

  void togglePromotions(bool val) {
    _promotionsEnabled = val;
    notifyListeners();
  }

  void toggleSecurityAlerts(bool val) {
    _securityAlertsEnabled = val;
    notifyListeners();
  }

  void updateSecuritySettings({bool? twoFactor, bool? biometrics}) {
    _currentUser = _currentUser.copyWith(
      twoFactorEnabled: twoFactor ?? _currentUser.twoFactorEnabled,
      biometricsEnabled: biometrics ?? _currentUser.biometricsEnabled,
    );
    notifyListeners();
  }

  void resetKyc() {
    _kyc = const KycModel(status: KycStatus.notSubmitted);
    _currentUser = _currentUser.copyWith(kycStatus: KycStatus.notSubmitted);
    notifyListeners();
  }

  // --- FINANCIAL OPERATIONS ---

  // 1. Add Money / Deposit Request
  String addMoneyDepositRequest({
    required String providerName,
    required double amount,
    required String senderAccount,
    required String transactionId,
    String? proofImageUrl,
  }) {
    final txId = 'DEP-${DateTime.now().millisecondsSinceEpoch}';

    // In a real flow, balance updates once approved, but we record transaction
    _walletBalance += amount;
    _totalAdded += amount;

    _transactions.insert(
      0,
      TransactionModel(
        id: txId,
        type: TransactionType.deposit,
        title: 'Add Money ($providerName)',
        description: 'Deposit via $providerName | Sender: $senderAccount',
        amount: amount,
        isCredit: true,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
        method: providerName,
        recipientOrSender: senderAccount,
        proofImageUrl: proofImageUrl,
        note: 'TrxID: $transactionId',
      ),
    );

    _notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Deposit Successful',
        message: '৳${amount.toStringAsFixed(0)} deposited via $providerName successfully.',
        category: NotificationCategory.wallet,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
    return txId;
  }

  // 2. Withdraw Request
  String? withdrawMoney({
    required String providerName,
    required double amount,
    required String receiverAccount,
  }) {
    const feePercentage = 0.015;
    final fee = amount * feePercentage;
    final totalDeduction = amount;

    if (totalDeduction > availableBalance) {
      return null;
    }

    _walletBalance -= totalDeduction;
    _totalWithdrawn += amount;

    final txId = 'WTH-${DateTime.now().millisecondsSinceEpoch}';

    _transactions.insert(
      0,
      TransactionModel(
        id: txId,
        type: TransactionType.withdraw,
        title: 'Withdraw ($providerName)',
        description: 'Withdrawal to $receiverAccount (Fee: ৳${fee.toStringAsFixed(1)})',
        amount: amount,
        fee: fee,
        isCredit: false,
        timestamp: DateTime.now(),
        status: TransactionStatus.processing,
        method: providerName,
        recipientOrSender: receiverAccount,
      ),
    );

    _notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Withdrawal Request Submitted',
        message: 'Your withdrawal of ৳${amount.toStringAsFixed(0)} is processing.',
        category: NotificationCategory.wallet,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
    return txId;
  }

  // 3. User-to-User Transfer (Send Money)
  String? sendMoneyToUser({
    required String recipientIdentifier,
    required String recipientName,
    required double amount,
    String? note,
  }) {
    if (amount > availableBalance) {
      return null;
    }

    _walletBalance -= amount;

    final txId = 'TRF-${DateTime.now().millisecondsSinceEpoch}';

    _transactions.insert(
      0,
      TransactionModel(
        id: txId,
        type: TransactionType.transferSent,
        title: 'Send Money to $recipientName',
        description: 'Transferred to @$recipientIdentifier',
        amount: amount,
        fee: 0.0,
        isCredit: false,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
        recipientOrSender: recipientIdentifier,
        note: note,
      ),
    );

    _notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Money Sent Successfully',
        message: 'You sent ৳${amount.toStringAsFixed(0)} to $recipientName (@$recipientIdentifier).',
        category: NotificationCategory.wallet,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
    return txId;
  }

  // 4. Buy Ticket
  TicketModel? buyTicket({
    required DrawModel draw,
    required String number,
    required int count,
    required int unitPrice,
    String paymentMethod = 'wallet',
  }) {
    final double total = (unitPrice * count).toDouble();

    if (paymentMethod == 'wallet') {
      if (total > availableBalance) {
        return null;
      }
      _walletBalance -= total;
    }

    _usedForTickets += total;

    final String ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch}';
    final String serialNum = 'TX-${DateTime.now().microsecond.toString().padLeft(6, '0')}';

    final ticket = TicketModel(
      id: ticketId,
      ticketNumber: serialNum,
      draw: draw,
      number: number,
      count: count,
      unitPrice: unitPrice,
      totalAmount: total.toInt(),
      purchaseDate: DateTime.now(),
      drawDate: draw.nextDrawDateTime,
      status: TicketStatus.active,
      transactionId: 'TX-${DateTime.now().millisecondsSinceEpoch}',
    );

    _tickets.insert(0, ticket);

    _transactions.insert(
      0,
      TransactionModel(
        id: ticket.transactionId,
        type: TransactionType.ticketPurchase,
        title: '${draw.title} Ticket ($number)',
        description: '$count Ticket(s) for ${draw.title}',
        amount: total,
        isCredit: false,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
        relatedDrawTitle: draw.title,
        relatedTicketNumber: number,
      ),
    );

    _notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Ticket Confirmed!',
        message: 'Your ticket for ${draw.title} ($number) was issued successfully.',
        category: NotificationCategory.draws,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
    return ticket;
  }

  // 5. Add / Remove / Update Saved Payment Method
  void addSavedPaymentMethod(PaymentMethodModel method) {
    if (method.isDefault) {
      for (int i = 0; i < _savedPaymentMethods.length; i++) {
        _savedPaymentMethods[i] = _savedPaymentMethods[i].copyWith(isDefault: false);
      }
    }
    _savedPaymentMethods.add(method);
    notifyListeners();
  }

  void updateSavedPaymentMethod(PaymentMethodModel method) {
    final index = _savedPaymentMethods.indexWhere((m) => m.id == method.id);
    if (index != -1) {
      if (method.isDefault) {
        for (int i = 0; i < _savedPaymentMethods.length; i++) {
          _savedPaymentMethods[i] = _savedPaymentMethods[i].copyWith(isDefault: false);
        }
      }
      _savedPaymentMethods[index] = method;
      notifyListeners();
    }
  }

  void setDefaultPaymentMethod(String id) {
    for (int i = 0; i < _savedPaymentMethods.length; i++) {
      _savedPaymentMethods[i] = _savedPaymentMethods[i].copyWith(
        isDefault: _savedPaymentMethods[i].id == id,
      );
    }
    notifyListeners();
  }

  void removeSavedPaymentMethod(String id) {
    _savedPaymentMethods.removeWhere((m) => m.id == id);
    if (_savedPaymentMethods.isNotEmpty && !_savedPaymentMethods.any((m) => m.isDefault)) {
      _savedPaymentMethods[0] = _savedPaymentMethods[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  // 6. Winning Number Checker Tool
  Map<String, dynamic> checkWinningNumber(String drawId, String userNumber) {
    final cleanNum = userNumber.trim();
    if (cleanNum.isEmpty) {
      return {'hasChecked': false};
    }

    final results = DrawResult.latestResults.where((r) => r.drawId == drawId).toList();
    if (results.isEmpty) {
      return {'hasChecked': true, 'isWinner': false, 'message': 'No recent results found for this draw.'};
    }

    final latest = results.first;
    final winningStr = latest.joinedWinningNumber;

    if (winningStr == cleanNum) {
      return {
        'hasChecked': true,
        'isWinner': true,
        'tier': '1st Prize (Jackpot)',
        'prize': latest.drawId == 'mega' ? '৳ 5,00,000' : (latest.drawId == 'daily' ? '৳ 50,000' : '৳ 20,000'),
        'drawTitle': latest.title,
        'date': latest.date,
        'match': '100% Exact Match',
      };
    } else if (cleanNum.length >= 2 && winningStr.endsWith(cleanNum.substring(cleanNum.length - 2))) {
      return {
        'hasChecked': true,
        'isWinner': true,
        'tier': '2nd Prize',
        'prize': latest.drawId == 'mega' ? '৳ 1,00,000' : (latest.drawId == 'daily' ? '৳ 2,500' : '৳ 1,000'),
        'drawTitle': latest.title,
        'date': latest.date,
        'match': 'Last 2 Digits Matched',
      };
    } else if (cleanNum.isNotEmpty && winningStr.endsWith(cleanNum.substring(cleanNum.length - 1))) {
      return {
        'hasChecked': true,
        'isWinner': true,
        'tier': '3rd Prize',
        'prize': latest.drawId == 'mega' ? '৳ 25,000' : (latest.drawId == 'daily' ? '৳ 250' : '৳ 100'),
        'drawTitle': latest.title,
        'date': latest.date,
        'match': 'Last Digit Matched',
      };
    } else {
      return {
        'hasChecked': true,
        'isWinner': false,
        'drawTitle': latest.title,
        'date': latest.date,
        'winningNumber': winningStr,
        'message': 'No prize match this time. Better luck in the next draw!',
      };
    }
  }

  // --- INITIAL SAMPLE SEED DATA ---
  void _initializeData() {
    // Seed Sample Tickets
    _tickets.addAll([
      TicketModel(
        id: 'TKT-001',
        ticketNumber: 'TX-948271',
        draw: DrawModel.sampleDraws[0],
        number: '1234567',
        count: 1,
        unitPrice: 100,
        totalAmount: 100,
        purchaseDate: DateTime.now().subtract(const Duration(hours: 3)),
        drawDate: DrawModel.sampleDraws[0].nextDrawDateTime,
        status: TicketStatus.active,
        transactionId: 'TX-948271',
      ),
      TicketModel(
        id: 'TKT-002',
        ticketNumber: 'TX-837192',
        draw: DrawModel.sampleDraws[1],
        number: '789',
        count: 2,
        unitPrice: 60,
        totalAmount: 120,
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        drawDate: DateTime.now().subtract(const Duration(hours: 10)),
        status: TicketStatus.won,
        winningAmount: 2500.0,
        transactionId: 'TX-837192',
        matchedDigitsCount: 2,
      ),
      TicketModel(
        id: 'TKT-003',
        ticketNumber: 'TX-726182',
        draw: DrawModel.sampleDraws[2],
        number: '456',
        count: 1,
        unitPrice: 20,
        totalAmount: 20,
        purchaseDate: DateTime.now().subtract(const Duration(hours: 5)),
        drawDate: DateTime.now().subtract(const Duration(hours: 4)),
        status: TicketStatus.lost,
        transactionId: 'TX-726182',
      ),
    ]);

    // Seed Sample Transactions
    _transactions.addAll([
      TransactionModel(
        id: 'TX-9481',
        type: TransactionType.winning,
        title: 'Daily Draw Prize Won',
        description: '2nd Prize Winner on Ticket #TX-837192',
        amount: 2500.00,
        isCredit: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 9)),
        status: TransactionStatus.completed,
      ),
      TransactionModel(
        id: 'TX-9480',
        type: TransactionType.deposit,
        title: 'Add Money (Nagad)',
        description: 'Manual Deposit via Nagad | TrxID: 9X82J3K',
        amount: 1000.00,
        isCredit: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 20)),
        status: TransactionStatus.completed,
        method: 'Nagad',
        recipientOrSender: '01712-345678',
      ),
      TransactionModel(
        id: 'TX-9479',
        type: TransactionType.ticketPurchase,
        title: 'Mega Draw Ticket (1234567)',
        description: '1 Ticket for Mega Draw',
        amount: 100.00,
        isCredit: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 22)),
        status: TransactionStatus.completed,
        relatedDrawTitle: 'Mega Draw',
        relatedTicketNumber: '1234567',
      ),
      TransactionModel(
        id: 'TX-9478',
        type: TransactionType.transferReceived,
        title: 'Received from Shakib_75',
        description: 'Internal User Transfer',
        amount: 500.00,
        isCredit: true,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        status: TransactionStatus.completed,
        recipientOrSender: 'shakib_75',
        note: 'For Mega Draw tickets',
      ),
      TransactionModel(
        id: 'TX-9477',
        type: TransactionType.withdraw,
        title: 'Withdraw (bKash)',
        description: 'Withdrawal to 01855-443322',
        amount: 500.00,
        fee: 7.5,
        isCredit: false,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        status: TransactionStatus.completed,
        method: 'bKash',
        recipientOrSender: '01855-443322',
      ),
      TransactionModel(
        id: 'TX-9476',
        type: TransactionType.bonus,
        title: 'Referral Signup Bonus',
        description: 'Bonus for inviting friend @rashed_dhaka',
        amount: 50.00,
        isCredit: true,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        status: TransactionStatus.completed,
      ),
    ]);

    // Seed Sample Saved Payment Methods
    _savedPaymentMethods.addAll([
      const PaymentMethodModel(
        id: 'user_nagad_1',
        provider: PaymentProvider.nagad,
        providerName: 'Nagad',
        accountNumber: '01712-345678',
        accountHolderName: 'Shek Ahmmed',
        accountType: 'Personal',
        isDefault: true,
      ),
      const PaymentMethodModel(
        id: 'user_bkash_1',
        provider: PaymentProvider.bkash,
        providerName: 'bKash',
        accountNumber: '01855-998877',
        accountHolderName: 'Shek Ahmmed',
        accountType: 'Personal',
        isDefault: false,
      ),
    ]);

    // Seed Sample Notifications
    _notifications.addAll([
      NotificationModel(
        id: 'notif_1',
        title: '🎉 Congratulations! You Won ৳2,500',
        message: 'Your ticket #TX-837192 in Daily Draw matched 2 digits and won 2nd prize!',
        category: NotificationCategory.winnings,
        timestamp: DateTime.now().subtract(const Duration(hours: 9)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_2',
        title: '🔥 Mega Draw ৳5,00,000 Countdown',
        message: 'Ticket sales closing soon for Mega Draw #43. Pick your 7 lucky numbers now!',
        category: NotificationCategory.draws,
        timestamp: DateTime.now().subtract(const Duration(hours: 15)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_3',
        title: '💰 Deposit of ৳1,000 Confirmed',
        message: 'Your Nagad deposit of ৳1,000 has been verified and added to your wallet.',
        category: NotificationCategory.wallet,
        timestamp: DateTime.now().subtract(const Duration(hours: 20)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notif_4',
        title: '🎁 Referral Bonus Credited',
        message: 'You earned ৳50 because your friend @rashed_dhaka registered with your code.',
        category: NotificationCategory.promotions,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
  }
}
