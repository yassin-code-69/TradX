import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/payment_method_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  PaymentProvider _selectedProvider = PaymentProvider.nagad;
  PaymentMethodModel? _selectedSavedAccount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final AppState _appState = AppState();

  final List<int> _presetAmounts = [500, 1000, 2500, 5000];
  bool _isProcessing = false;
  bool _useNewAccount = false;

  @override
  void initState() {
    super.initState();
    _initSavedAccount();
  }

  void _initSavedAccount() {
    final saved = _appState.savedPaymentMethods;
    final match = saved.where((m) => m.provider == _selectedProvider).toList();
    if (match.isNotEmpty) {
      _selectedSavedAccount = match.first;
      _accountNumberController.text = _selectedSavedAccount!.accountNumber;
      _accountHolderController.text = _selectedSavedAccount!.accountHolderName;
      _useNewAccount = false;
    } else {
      _selectedSavedAccount = null;
      _useNewAccount = true;
      _accountNumberController.clear();
      _accountHolderController.text = _appState.currentUser.fullName;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _onProviderChanged(PaymentProvider provider) {
    setState(() {
      _selectedProvider = provider;
      _initSavedAccount();
    });
    HapticFeedback.selectionClick();
  }

  double get _enteredAmount {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  double get _feeAmount {
    return _enteredAmount * 0.015; // 1.5% withdrawal fee
  }

  double get _netPayoutAmount {
    final net = _enteredAmount - _feeAmount;
    return net > 0 ? net : 0.0;
  }

  bool get _isFormValid {
    final amt = _enteredAmount;
    final acc = _accountNumberController.text.trim();
    return amt >= 100 && amt <= 25000 && amt <= _appState.availableBalance && acc.length >= 8;
  }

  void _handleWithdrawal() async {
    final amount = _enteredAmount;
    final accountNumber = _accountNumberController.text.trim();

    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum withdrawal amount is ৳ 100'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (amount > 25000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum single withdrawal limit is ৳ 25,000'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (amount > _appState.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient available balance (Available: ৳ ${_appState.formattedAvailableBalance})'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (accountNumber.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payout account number'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final providerName = _selectedProvider == PaymentProvider.nagad
        ? 'Nagad'
        : _selectedProvider == PaymentProvider.bkash
            ? 'bKash'
            : _selectedProvider == PaymentProvider.rocket
                ? 'Rocket'
                : 'Bank Transfer';

    final txId = _appState.withdrawMoney(
      providerName: providerName,
      amount: amount,
      receiverAccount: accountNumber,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (txId != null) {
      HapticFeedback.heavyImpact();
      _showWithdrawalReceiptModal(
        txId: txId,
        providerName: providerName,
        amount: amount,
        fee: _feeAmount,
        netPayout: _netPayoutAmount,
        accountNumber: accountNumber,
      );
    }
  }

  void _showWithdrawalReceiptModal({
    required String txId,
    required String providerName,
    required double amount,
    required double fee,
    required double netPayout,
    required String accountNumber,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorderHighlight, width: 1.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Processing Status Aura
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.goldPrimary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Withdrawal Processing',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Funds will arrive in your account within 5 - 30 minutes',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              TradexReceiptCard(
                title: 'Withdraw via $providerName',
                status: 'PROCESSING',
                statusColor: AppColors.goldPrimary,
                amount: '৳ ${netPayout.toStringAsFixed(2)}',
                idLabel: 'WITHDRAWAL TXID',
                idValue: txId,
                details: [
                  MapEntry('Requested Amount', '৳ ${amount.toStringAsFixed(2)}'),
                  MapEntry('Gateway Fee (1.5%)', '৳ ${fee.toStringAsFixed(2)}'),
                  MapEntry('Net Dispatched Payout', '৳ ${netPayout.toStringAsFixed(2)}'),
                  MapEntry('Destination Account', accountNumber),
                  MapEntry('Estimated Delivery', '5 - 30 Mins (Instant)'),
                  MapEntry('Date & Time', 'Just now'),
                ],
                onCopyId: () {
                  Clipboard.setData(ClipboardData(text: txId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawal TXID copied to clipboard!'),
                      backgroundColor: AppColors.greenDark,
                    ),
                  );
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawal receipt shared!'),
                      backgroundColor: AppColors.cardBgElevated,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              TradexButton(
                text: 'DONE / RETURN TO WALLET',
                variant: TradexButtonVariant.primaryGold,
                height: 50,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedMatchingAccounts = _appState.savedPaymentMethods
        .where((m) => m.provider == _selectedProvider)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Withdraw Funds',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Balance Overview Card (Available vs Locked)
              ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1710), Color(0xFF0F0E13)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available for Withdrawal',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳ ${_appState.formattedAvailableBalance}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenLight,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.cardBorderHighlight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.goldAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Locked: ৳ ${_appState.formattedLockedBalance}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.goldAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ৳ ${_appState.formattedBalance}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              // 2. Select Withdrawal Method
              Text(
                '1. Select Withdrawal Gateway',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _buildProviderTab(PaymentProvider.nagad, 'নগদ', AppColors.nagad),
                  const SizedBox(width: 8),
                  _buildProviderTab(PaymentProvider.bkash, 'বিকাশ', AppColors.bkash),
                  const SizedBox(width: 8),
                  _buildProviderTab(PaymentProvider.rocket, 'Rocket', AppColors.rocket),
                  const SizedBox(width: 8),
                  _buildProviderTab(PaymentProvider.bank, 'Bank', AppColors.bank),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Saved Account Selector or Enter New Account
              Text(
                '2. Payout Account',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              if (savedMatchingAccounts.isNotEmpty) ...[
                Column(
                  children: savedMatchingAccounts.map((acc) {
                    final isSelected = !_useNewAccount && _selectedSavedAccount?.id == acc.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _useNewAccount = false;
                          _selectedSavedAccount = acc;
                          _accountNumberController.text = acc.accountNumber;
                          _accountHolderController.text = acc.accountHolderName;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.cardBgElevated : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? acc.brandColor : AppColors.cardBorder,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? acc.brandColor : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${acc.providerName} - ${acc.accountNumber}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Account Holder: ${acc.accountHolderName} (${acc.accountType})',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (acc.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.greenBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SAVED',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.greenLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Option to toggle new account
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _useNewAccount = true;
                      _selectedSavedAccount = null;
                      _accountNumberController.clear();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _useNewAccount ? AppColors.cardBgElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _useNewAccount ? AppColors.goldPrimary : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _useNewAccount ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: _useNewAccount ? AppColors.goldPrimary : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '+ Enter a different account number',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _useNewAccount ? AppColors.goldLight : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_useNewAccount || savedMatchingAccounts.isEmpty) ...[
                TradexTextField(
                  controller: _accountNumberController,
                  label: 'Receiver Account Number / Phone',
                  hint: 'e.g. 017xxxxxxxx',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TradexTextField(
                  controller: _accountHolderController,
                  label: 'Account Holder Full Name',
                  hint: 'e.g. Shek Ahmmed',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
              ],

              // 4. Withdrawal Amount Input
              Text(
                '3. Withdrawal Amount',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _enteredAmount > _appState.availableBalance
                        ? AppColors.redAccent
                        : AppColors.cardBorderHighlight,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '৳',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0.00 (Min ৳ 100)',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _amountController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _amountController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              if (_enteredAmount > _appState.availableBalance) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Amount exceeds available balance of ৳ ${_appState.formattedAvailableBalance}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Preset Amount Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ..._presetAmounts.map((amt) {
                    final isSelected = _amountController.text == amt.toString();
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _amountController.text = amt.toString();
                          setState(() {});
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.goldPrimary.withValues(alpha: 0.25)
                                : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '৳ $amt',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _amountController.text = _appState.availableBalance.toStringAsFixed(0);
                        setState(() {});
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'MAX',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Real-time 1.5% Fee Calculation & Net Payout Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBgElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cardBorderHighlight,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    _buildCalcRow(
                      'Withdrawal Amount',
                      '৳ ${_enteredAmount > 0 ? _enteredAmount.toStringAsFixed(2) : "0.00"}',
                      Colors.white,
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _buildCalcRow(
                      'Gateway Fee (1.5%)',
                      '- ৳ ${_feeAmount > 0 ? _feeAmount.toStringAsFixed(2) : "0.00"}',
                      AppColors.orangeAccent,
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'You Will Receive',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '৳ ${_netPayoutAmount > 0 ? _netPayoutAmount.toStringAsFixed(2) : "0.00"}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 6. Slide to Confirm / Submit Action
              if (_isProcessing) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: AppColors.goldPrimary),
                  ),
                ),
              ] else if (_isFormValid) ...[
                TradexSlideToConfirm(
                  label: 'SLIDE TO WITHDRAW',
                  sliderColor: AppColors.goldPrimary,
                  onConfirmed: _handleWithdrawal,
                ),
              ] else ...[
                TradexButton(
                  text: 'ENTER VALID AMOUNT & ACCOUNT',
                  variant: TradexButtonVariant.outline,
                  height: 52,
                  onPressed: null,
                ),
              ],

              const SizedBox(height: 16),

              // Payout Speed Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on_rounded, color: AppColors.greenLight, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Instant Express Dispatches within 5 to 30 mins',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderTab(PaymentProvider provider, String name, Color color) {
    final isSelected = _selectedProvider == provider;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onProviderChanged(provider),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
