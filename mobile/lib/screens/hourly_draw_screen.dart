import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/live_draw_screen.dart';
import 'package:tradex/screens/ticket_purchase_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/draw_icons.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class HourlyDrawScreen extends StatefulWidget {
  const HourlyDrawScreen({super.key});

  @override
  State<HourlyDrawScreen> createState() => _HourlyDrawScreenState();
}

class _HourlyDrawScreenState extends State<HourlyDrawScreen> {
  final List<String> _selectedDigits = ['', '', ''];
  int _ticketCount = 1;
  static const int _ticketPrice = 20;
  final DrawModel _hourlyDraw = DrawModel.sampleDraws[2];

  int _secondsRemaining = 18 * 60 + 42;
  Timer? _timer;

  static const List<int> _quickBetPresets = [1, 2, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && mounted) {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final int hours = _secondsRemaining ~/ 3600;
    final int mins = (_secondsRemaining % 3600) ~/ 60;
    final int secs = _secondsRemaining % 60;
    return '${hours.toString().padLeft(2, '0')} : ${mins.toString().padLeft(2, '0')} : ${secs.toString().padLeft(2, '0')}';
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
              const Icon(Icons.flash_on_rounded, color: AppColors.purpleAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                'Please pick 3 digits for hourly draw',
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
          draw: _hourlyDraw,
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
          'Hourly Draw',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tv_rounded, color: AppColors.purpleLight, size: 22),
            tooltip: 'Live Draw',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveDrawScreen(draw: _hourlyDraw),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Next Draw Countdown Banner Card
              _buildHourlyCountdownBanner(),

              const SizedBox(height: 18),

              // 2. 3-Digit Selector Header & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RAPID 3-DIGIT SELECTOR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (filledCount > 0)
                    GestureDetector(
                      onTap: _onClearAllPressed,
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. 3-Digit Display Large Glowing Circles
              _buildDigitDisplayCircles(),

              const SizedBox(height: 16),

              // 4. Quick Bet Presets
              _buildQuickBetPresets(),

              const SizedBox(height: 16),

              // 5. 0-9 Keypad
              _buildKeypad(),

              const SizedBox(height: 16),

              // 6. Ticket Price & Quantity Stepper
              _buildPriceAndStepperRow(totalAmount),

              const SizedBox(height: 16),

              // 7. BUY TICKET CTA (Purple/Magenta Gradient)
              TradexButton(
                text: 'BUY TICKET • ৳ $totalAmount',
                variant: TradexButtonVariant.secondaryPurple,
                height: 52,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                onPressed: _handleBuyTicket,
              ),

              const SizedBox(height: 12),

              // 8. Live Draw Link
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveDrawScreen(draw: _hourlyDraw),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.purpleLight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Every Hour  •  Watch Live Stream',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purpleLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.purpleLight, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyCountdownBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purpleAccent.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleAccent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Draw In',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'HR        ',
                    style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'MIN       ',
                    style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'SEC',
                    style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Prize ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '৳ 20,000',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const HourlyDrawClockIcon(size: 60),
        ],
      ),
    );
  }

  Widget _buildDigitDisplayCircles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final String digit = _selectedDigits[index];
        final bool isFilled = digit.isNotEmpty;
        final bool isCurrentEmpty = !isFilled &&
            (index == 0 || _selectedDigits[index - 1].isNotEmpty);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.cardBgElevated : AppColors.backgroundSecondary,
            border: Border.all(
              color: isFilled
                  ? AppColors.purpleAccent
                  : (isCurrentEmpty ? AppColors.purpleLight.withValues(alpha: 0.7) : AppColors.cardBorder),
              width: isFilled ? 2.2 : (isCurrentEmpty ? 1.6 : 1),
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.purpleAccent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isCurrentEmpty
                    ? [
                        BoxShadow(
                          color: AppColors.purpleAccent.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ]
                    : null),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickBetPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK BET PRESETS',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _quickBetPresets.map((qty) {
            final bool isSelected = _ticketCount == qty;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _ticketCount = qty);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.purpleAccent.withValues(alpha: 0.2)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.purpleAccent
                            : AppColors.cardBorder,
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          '${qty}x',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.purpleLight : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '৳${qty * _ticketPrice}',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.purpleAccent.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.casino_outlined, color: AppColors.purpleLight, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Quick Pick',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.purpleLight,
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
                    height: 48,
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
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              digit,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceAndStepperRow(int totalAmount) {
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
                    color: AppColors.purpleLight,
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
