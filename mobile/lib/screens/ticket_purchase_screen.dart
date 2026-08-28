import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/ticket_model.dart';
import 'package:tradex/screens/add_money_screen.dart';
import 'package:tradex/screens/purchase_success_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/payment_logos.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

enum PurchasePaymentMode { wallet, bkash, nagad, rocket }

class TicketPurchaseScreen extends StatefulWidget {
  final DrawModel draw;
  final String selectedNumber;
  final int initialTicketCount;
  final int? unitPrice;

  const TicketPurchaseScreen({
    super.key,
    required this.draw,
    required this.selectedNumber,
    this.initialTicketCount = 1,
    this.unitPrice,
  });

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  final AppState _appState = AppState();
  late int _quantity;
  late int _unitPrice;
  PurchasePaymentMode _selectedMode = PurchasePaymentMode.wallet;
  bool _isProcessing = false;
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();

  static const List<int> _presetQuantities = [1, 2, 5, 10, 25];

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialTicketCount.clamp(1, 100);
    _unitPrice = widget.unitPrice ?? widget.draw.unitPriceInt;
    _senderPhoneController.text = _appState.currentUser.phone;
  }

  @override
  void dispose() {
    _senderPhoneController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  int get _subtotal => _unitPrice * _quantity;
  int get _discount => 0; // Promotional discounts or coupons can be added
  int get _totalPayable => _subtotal - _discount;
  bool get _hasSufficientBalance => _appState.availableBalance >= _totalPayable;

  Future<void> _handleConfirmPurchase() async {
    if (_isProcessing) return;

    if (_selectedMode == PurchasePaymentMode.wallet && !_hasSufficientBalance) {
      HapticFeedback.vibrate();
      _showInsufficientBalanceModal();
      return;
    }

    if (_selectedMode != PurchasePaymentMode.wallet) {
      if (_senderPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your sender mobile number'),
            backgroundColor: AppColors.cardBgElevated,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 900));

    final String paymentMethodStr = _selectedMode == PurchasePaymentMode.wallet
        ? 'wallet'
        : _selectedMode.name;

    final TicketModel? newTicket = _appState.buyTicket(
      draw: widget.draw,
      number: widget.selectedNumber,
      count: _quantity,
      unitPrice: _unitPrice,
      paymentMethod: paymentMethodStr,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (newTicket != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(ticket: newTicket),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to complete purchase. Please check your balance.'),
          backgroundColor: AppColors.redAccent.withValues(alpha: 0.9),
        ),
      );
    }
  }

  void _showInsufficientBalanceModal() {
    final double deficit = _totalPayable - _appState.availableBalance;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Insufficient Wallet Balance',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have ৳${_appState.formattedAvailableBalance} available. You need an additional ৳${deficit.toStringAsFixed(0)} to buy $_quantity ticket(s).',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TradexButton(
                text: 'ADD ৳${(deficit.ceil() > 100 ? deficit.ceil() : 100)} TO WALLET',
                variant: TradexButtonVariant.primaryGold,
                height: 48,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMoneyScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TradexButton(
                text: 'Pay with bKash/Nagad Directly',
                variant: TradexButtonVariant.glass,
                height: 44,
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedMode = PurchasePaymentMode.bkash;
                  });
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
    final digits = widget.selectedNumber.split('');

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
          'Review & Buy Ticket',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Draw Header Info Card
                    _buildDrawHeaderCard(),

                    const SizedBox(height: 16),

                    // 2. Selected Numbers Display Card
                    _buildSelectedNumberCard(digits),

                    const SizedBox(height: 18),

                    // 3. Ticket Quantity Selector
                    _buildQuantitySelector(),

                    const SizedBox(height: 20),

                    // 4. Payment Method Selector
                    _buildPaymentMethodSelector(),

                    const SizedBox(height: 20),

                    // 5. Pricing Breakdown Table
                    _buildPricingBreakdownCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 6. Bottom Sticky Confirm Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.draw.accentColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.draw.accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: widget.draw.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.draw.accentColor.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: widget.draw.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.draw.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TradexStatusChip(
                      label: widget.draw.ticketPrice,
                      color: widget.draw.accentColor,
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.draw.scheduleInfo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Jackpot',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                widget.draw.prize,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: widget.draw.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedNumberCard(List<String> digits) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECTED COMBINATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${digits.length} Digits',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: digits.map((d) {
                return Container(
                  width: digits.length > 5 ? 36 : 48,
                  height: digits.length > 5 ? 42 : 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.draw.accentColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.draw.accentColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    d,
                    style: GoogleFonts.poppins(
                      fontSize: digits.length > 5 ? 18 : 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TICKET QUANTITY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Multiply winning entries',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of Tickets',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderHighlight),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        if (_quantity > 1) {
                          HapticFeedback.selectionClick();
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        if (_quantity < 100) {
                          HapticFeedback.selectionClick();
                          setState(() => _quantity++);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Presets Row
          Row(
            children: _presetQuantities.map((preset) {
              final bool isSelected = _quantity == preset;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _quantity = preset);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.draw.accentColor.withValues(alpha: 0.2)
                            : AppColors.cardBgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? widget.draw.accentColor
                              : AppColors.cardBorder,
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${preset}x',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? widget.draw.accentColor : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final available = _appState.availableBalance;
        final bool canPayWithWallet = available >= _totalPayable;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYMENT METHOD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),

              // Option 1: Wallet Balance
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMode = PurchasePaymentMode.wallet);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedMode == PurchasePaymentMode.wallet
                        ? AppColors.goldPrimary.withValues(alpha: 0.12)
                        : AppColors.cardBgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedMode == PurchasePaymentMode.wallet
                          ? AppColors.goldPrimary
                          : AppColors.cardBorder,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.goldPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Tradex Main Wallet',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (canPayWithWallet)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.greenLight,
                                    size: 15,
                                  )
                                else
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.redAccent,
                                    size: 15,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Available: ৳ ${_appState.formattedAvailableBalance}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: canPayWithWallet
                                    ? AppColors.greenLight
                                    : AppColors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedMode == PurchasePaymentMode.wallet
                              ? AppColors.goldPrimary
                              : Colors.transparent,
                          border: Border.all(
                            color: _selectedMode == PurchasePaymentMode.wallet
                                ? AppColors.goldPrimary
                                : AppColors.cardBorderHighlight,
                            width: 2,
                          ),
                        ),
                        child: _selectedMode == PurchasePaymentMode.wallet
                            ? const Icon(Icons.check, size: 14, color: Colors.black)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Direct Mobile Banking (bKash, Nagad, Rocket)
              Text(
                'Direct Mobile Banking',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildProviderCard(
                    title: 'bKash',
                    logo: const BKashBadgeIcon(size: 24),
                    mode: PurchasePaymentMode.bkash,
                    color: AppColors.bkash,
                  ),
                  const SizedBox(width: 8),
                  _buildProviderCard(
                    title: 'Nagad',
                    logo: const NagadBadgeIcon(size: 24),
                    mode: PurchasePaymentMode.nagad,
                    color: AppColors.nagad,
                  ),
                  const SizedBox(width: 8),
                  _buildProviderCard(
                    title: 'Rocket',
                    logo: const RocketBadgeIcon(size: 24),
                    mode: PurchasePaymentMode.rocket,
                    color: AppColors.rocket,
                  ),
                ],
              ),

              if (_selectedMode != PurchasePaymentMode.wallet) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Payment Instructions:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send ৳ $_totalPayable to Merchant Number 01712-345678 and enter your sender number below.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TradexTextField(
                        controller: _senderPhoneController,
                        label: 'Your Sender Phone Number',
                        hint: '01XXXXXXXXX',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderCard({
    required String title,
    required Widget logo,
    required PurchasePaymentMode mode,
    required Color color,
  }) {
    final bool isSelected = _selectedMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.cardBgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              logo,
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRICING BREAKDOWN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Unit Ticket Price', '৳ $_unitPrice'),
          _buildPriceRow('Quantity', 'x $_quantity Tickets'),
          _buildPriceRow('Subtotal', '৳ $_subtotal'),
          _buildPriceRow('Promotional Bonus', '- ৳ 0 (0%)', isGreen: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '৳ $_totalPayable',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.goldPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGreen ? AppColors.greenLight : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgElevated,
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TradexSlideToConfirm(
            label: 'SLIDE TO CONFIRM ৳$_totalPayable',
            sliderColor: widget.draw.accentColor,
            onConfirmed: _handleConfirmPurchase,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '256-Bit Encrypted & Provably Fair Draw Entry',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
