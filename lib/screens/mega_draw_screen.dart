import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/mega_draw_info_screen.dart';
import 'package:tradex/screens/ticket_purchase_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/draw_icons.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class MegaDrawScreen extends StatefulWidget {
  const MegaDrawScreen({super.key});

  @override
  State<MegaDrawScreen> createState() => _MegaDrawScreenState();
}

class _MegaDrawScreenState extends State<MegaDrawScreen> with SingleTickerProviderStateMixin {
  final List<String> _selectedDigits = ['', '', '', '', '', '', ''];
  int _ticketCount = 1;
  static const int _ticketPrice = 100;
  final DrawModel _megaDraw = DrawModel.sampleDraws[0];

  late AnimationController _glowPulseController;
  late Animation<double> _glowPulseAnimation;

  @override
  void initState() {
    super.initState();
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowPulseAnimation = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowPulseController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      for (int i = 0; i < _selectedDigits.length; i++) {
        if (_selectedDigits[i].isEmpty) {
          _selectedDigits[i] = digit;
          break;
        }
      }
    });
  }

  void _onDeletePressed() {
    HapticFeedback.selectionClick();
    setState(() {
      for (int i = _selectedDigits.length - 1; i >= 0; i--) {
        if (_selectedDigits[i].isNotEmpty) {
          _selectedDigits[i] = '';
          break;
        }
      }
    });
  }

  void _onClearAllPressed() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (int i = 0; i < _selectedDigits.length; i++) {
        _selectedDigits[i] = '';
      }
    });
  }

  void _onQuickPick() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    setState(() {
      for (int i = 0; i < _selectedDigits.length; i++) {
        _selectedDigits[i] = random.nextInt(10).toString();
      }
    });
  }

  void _handleBuyTicket() {
    final bool isNumberComplete = _selectedDigits.every((d) => d.isNotEmpty);
    if (!isNumberComplete) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.goldPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Please select all 7 digits or tap Quick Pick',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.cardBgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketPurchaseScreen(
          draw: _megaDraw,
          selectedNumber: _selectedDigits.join(''),
          initialTicketCount: _ticketCount,
          unitPrice: _ticketPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount = _ticketPrice * _ticketCount;
    final bool isNumberComplete = _selectedDigits.every((d) => d.isNotEmpty);
    final int filledCount = _selectedDigits.where((d) => d.isNotEmpty).length;

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
          'Mega Draw',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.goldPrimary, size: 22),
            tooltip: 'Prize Info',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MegaDrawInfoScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Hero Jackpot Trophy & Banner
              _buildHeroJackpotBanner(),

              const SizedBox(height: 14),

              // 2. Next Mega Draw Schedule & Countdown Card
              _buildScheduleCard(),

              const SizedBox(height: 16),

              // 3. 7-Digit Interactive Slot Reel Section Header & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT 7 DIGIT COMBINATION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      if (filledCount > 0)
                        GestureDetector(
                          onTap: _onClearAllPressed,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        '$filledCount / 7 Selected',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isNumberComplete
                              ? AppColors.greenLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 4. 7-Digit Display Slots (Slot Reel Aesthetics)
              _buildDigitSlotsRow(),

              const SizedBox(height: 14),

              // 5. 0-9 Keypad + Quick Pick + Backspace
              _buildKeypad(),

              const SizedBox(height: 14),

              // 6. Ticket Quantity & Price Selector Row
              _buildQuantityAndPriceRow(totalAmount),

              const SizedBox(height: 14),

              // 7. BUY TICKET CTA
              TradexButton(
                text: 'BUY TICKET • ৳ $totalAmount',
                variant: TradexButtonVariant.primaryGold,
                height: 52,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                onPressed: _handleBuyTicket,
              ),

              const SizedBox(height: 10),

              // 8. Footer Link to Info
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MegaDrawInfoScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View guaranteed prize tiers & rules',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.goldPrimary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroJackpotBanner() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFEE58),
              Color(0xFFFFD54F),
              Color(0xFFFFA000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'MEGA DRAW JACKPOT',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '1st of Every Month • Guaranteed ৳ 5,00,000 Winner',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        // Glowing Trophy with animated radiant aura
        AnimatedBuilder(
          animation: _glowPulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldPrimary.withValues(alpha: _glowPulseAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const MegaDrawTrophyIcon(size: 72),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Mega Draw',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                _megaDraw.scheduleInfo,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          CountdownTimerWidget(
            targetDateTime: _megaDraw.nextDrawDateTime,
            accentColor: AppColors.goldPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildDigitSlotsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final String digit = _selectedDigits[index];
        final bool isFilled = digit.isNotEmpty;
        final bool isCurrentEmpty = !isFilled &&
            (index == 0 || _selectedDigits[index - 1].isNotEmpty);

        return Container(
          width: 40,
          height: 48,
          decoration: BoxDecoration(
            color: isFilled ? AppColors.cardBgElevated : AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFilled
                  ? AppColors.goldPrimary
                  : (isCurrentEmpty ? AppColors.goldAccent.withValues(alpha: 0.6) : AppColors.cardBorder),
              width: isFilled ? 1.8 : (isCurrentEmpty ? 1.4 : 1),
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isCurrentEmpty
                    ? [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ]
                    : null),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isFilled ? Colors.white : AppColors.textMuted,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: ['1', '2', '3'].map((d) => _buildKey(d)).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['4', '5', '6'].map((d) => _buildKey(d)).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['7', '8', '9'].map((d) => _buildKey(d)).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: _onQuickPick,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.casino_outlined, color: AppColors.goldPrimary, size: 17),
                        const SizedBox(width: 6),
                        Text(
                          'Quick Pick',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildKey('0'),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: _onDeletePressed,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => _onDigitPressed(digit),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              digit,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityAndPriceRow(int totalAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Price',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              '৳ $_ticketPrice / tkt',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  if (_ticketCount > 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _ticketCount--);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$_ticketCount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  if (_ticketCount < 100) {
                    HapticFeedback.selectionClick();
                    setState(() => _ticketCount++);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
