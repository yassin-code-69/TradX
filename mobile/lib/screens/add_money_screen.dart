import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/payment_method_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/draw_icons.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class AddMoneyScreen extends StatefulWidget {
  final double? prefilledAmount;

  const AddMoneyScreen({super.key, this.prefilledAmount});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  PaymentProvider _selectedProvider = PaymentProvider.nagad;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _senderAccountController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();

  final List<int> _presetAmounts = [100, 500, 1000, 2500, 5000];
  final AppState _appState = AppState();

  bool _isProcessing = false;
  bool _hasMockScreenshot = false;
  String _mockFileName = 'payment_receipt_proof.jpg';
  String _mockFileSize = '1.4 MB';

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAmount != null && widget.prefilledAmount! > 0) {
      _amountController.text = widget.prefilledAmount!.toInt().toString();
    }
    // Default sender account to user's phone for convenience
    _senderAccountController.text = _appState.currentUser.phone.replaceAll('+880 ', '').replaceAll('-', '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _senderAccountController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  PaymentMethodModel get _currentAdminAccount {
    return PaymentMethodModel.adminDepositAccounts.firstWhere(
      (m) => m.provider == _selectedProvider,
      orElse: () => PaymentMethodModel.adminDepositAccounts.first,
    );
  }

  void _copyAdminAccount(PaymentMethodModel account) {
    Clipboard.setData(ClipboardData(text: account.accountNumber));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.greenLight, size: 18),
            const SizedBox(width: 8),
            Text('${account.providerName} number copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.cardBgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _pickMockScreenshot() {
    HapticFeedback.selectionClick();
    setState(() {
      _hasMockScreenshot = true;
      _mockFileName = 'trx_proof_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.png';
      _mockFileSize = '1.8 MB';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment screenshot proof attached!'),
        backgroundColor: AppColors.greenDark,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeMockScreenshot() {
    HapticFeedback.selectionClick();
    setState(() {
      _hasMockScreenshot = false;
    });
  }

  void _handleSubmitDeposit() async {
    final String amountText = _amountController.text.trim();
    final double? amount = double.tryParse(amountText);
    final String senderAccount = _senderAccountController.text.trim();
    final String trxId = _trxIdController.text.trim().toUpperCase();

    if (amount == null || amount < _currentAdminAccount.minDeposit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum deposit for ${_currentAdminAccount.providerName} is ৳ ${_currentAdminAccount.minDeposit.toStringAsFixed(0)}'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (amount > _currentAdminAccount.maxDeposit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum deposit for ${_currentAdminAccount.providerName} is ৳ ${_currentAdminAccount.maxDeposit.toStringAsFixed(0)}'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (senderAccount.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Sender Account Number / Phone'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (trxId.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Transaction ID (TrxID)'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final generatedTxId = _appState.addMoneyDepositRequest(
      providerName: _currentAdminAccount.providerName,
      amount: amount,
      senderAccount: senderAccount,
      transactionId: trxId,
      proofImageUrl: _hasMockScreenshot ? 'assets/proof.png' : null,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    HapticFeedback.heavyImpact();
    _showDepositConfirmationReceipt(
      generatedTxId: generatedTxId,
      amount: amount,
      trxId: trxId,
      senderAccount: senderAccount,
    );
  }

  void _showDepositConfirmationReceipt({
    required String generatedTxId,
    required double amount,
    required String trxId,
    required String senderAccount,
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

              // Success Aura
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.greenAccent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.greenAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenAccent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.greenLight,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Deposit Request Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳ ${amount.toStringAsFixed(2)} has been credited to your wallet',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              TradexReceiptCard(
                title: 'Add Money (${_currentAdminAccount.providerName})',
                status: 'COMPLETED',
                statusColor: AppColors.greenLight,
                amount: '৳ ${amount.toStringAsFixed(2)}',
                idLabel: 'SYSTEM TXID',
                idValue: generatedTxId,
                details: [
                  MapEntry('Payment Gateway', _currentAdminAccount.providerName),
                  MapEntry('Sender Account', senderAccount),
                  MapEntry('Provider TrxID', trxId),
                  MapEntry('Status', 'Auto-Verified & Added'),
                  MapEntry('Proof Attached', _hasMockScreenshot ? 'Yes (Screenshot)' : 'N/A'),
                  MapEntry('Date & Time', 'Just now'),
                ],
                onCopyId: () {
                  Clipboard.setData(ClipboardData(text: generatedTxId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction ID copied!'),
                      backgroundColor: AppColors.greenDark,
                    ),
                  );
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deposit receipt shared!'),
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
                  Navigator.pop(ctx); // close modal
                  Navigator.pop(context); // close add money screen
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
    final currentAccount = _currentAdminAccount;

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
          'Add Money / Deposit',
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
              // 1. Current Wallet Balance Pill Header
              ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Wallet Balance',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '৳ ${_appState.formattedBalance}',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const WalletChestGraphic(),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              // 2. Select Payment Method Grid
              Text(
                '1. Select Deposit Method',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _buildProviderTab(
                    provider: PaymentProvider.nagad,
                    name: 'নগদ (Nagad)',
                    color: AppColors.nagad,
                  ),
                  const SizedBox(width: 8),
                  _buildProviderTab(
                    provider: PaymentProvider.bkash,
                    name: 'বিকাশ (bKash)',
                    color: AppColors.bkash,
                  ),
                  const SizedBox(width: 8),
                  _buildProviderTab(
                    provider: PaymentProvider.rocket,
                    name: 'Rocket',
                    color: AppColors.rocket,
                  ),
                  const SizedBox(width: 8),
                  _buildProviderTab(
                    provider: PaymentProvider.bank,
                    name: 'Bank',
                    color: AppColors.bank,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Official Admin Payment Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentAccount.brandColor.withValues(alpha: 0.15),
                      AppColors.cardBgElevated,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: currentAccount.brandColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentAccount.brandColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentAccount.providerName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: currentAccount.brandColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentAccount.accountType,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greenBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OFFICIAL',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Copyable Account Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OFFICIAL DEPOSIT NUMBER',
                                style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentAccount.accountNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentAccount.brandColor.withValues(alpha: 0.2),
                              foregroundColor: currentAccount.brandColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: currentAccount.brandColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            onPressed: () => _copyAdminAccount(currentAccount),
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: Text(
                              'COPY',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (currentAccount.bankName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Bank: ${currentAccount.bankName} | Branch: ${currentAccount.branchName}',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Routing: ${currentAccount.routingNumber} | AC Name: ${currentAccount.accountHolderName}',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Quick Step Guide
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentAccount.instructions,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 4. Enter Amount
              Text(
                '2. Enter Deposit Amount',
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '৳',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purpleLight,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'Enter amount (Min ৳ ${currentAccount.minDeposit.toInt()})',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Preset Amount Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _presetAmounts.map((amt) {
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
                              ? AppColors.purpleButton.withValues(alpha: 0.3)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.purpleLight : AppColors.cardBorder,
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
                }).toList(),
              ),

              const SizedBox(height: 22),

              // 5. Sender Account & TrxID Verification
              Text(
                '3. Verification Details',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Sender Account Number
              TradexTextField(
                controller: _senderAccountController,
                label: 'Your Sender Number / Account',
                hint: 'e.g. 01712345678',
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              // Transaction ID (TrxID)
              TradexTextField(
                controller: _trxIdController,
                label: 'Transaction ID (TrxID)',
                hint: 'e.g. 9X82J3KLM',
                prefixIcon: Icons.tag_rounded,
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 20),

              // 6. Payment Proof Screenshot Upload Simulation
              Text(
                '4. Payment Screenshot (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              if (!_hasMockScreenshot) ...[
                GestureDetector(
                  onTap: _pickMockScreenshot,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardBorderHighlight,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.purpleAccent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.purpleLight,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap to attach payment proof screenshot',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PNG, JPG up to 10MB',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.greenAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.greenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.greenLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mockFileName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _mockFileSize,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ATTACHED ✓',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.redAccent, size: 20),
                        onPressed: _removeMockScreenshot,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // 7. Submit Button
              TradexButton(
                text: 'SUBMIT DEPOSIT REQUEST',
                variant: TradexButtonVariant.primaryGold,
                height: 52,
                fontSize: 14.5,
                isLoading: _isProcessing,
                onPressed: _handleSubmitDeposit,
              ),

              const SizedBox(height: 16),

              // Secure SSL Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Manual deposits verified within 1-5 minutes 24/7',
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

  Widget _buildProviderTab({
    required PaymentProvider provider,
    required String name,
    required Color color,
  }) {
    final isSelected = _selectedProvider == provider;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProvider = provider;
          });
          HapticFeedback.selectionClick();
        },
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
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
