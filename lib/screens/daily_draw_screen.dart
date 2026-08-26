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

class DailyDrawScreen extends StatefulWidget {
  const DailyDrawScreen({super.key});

  @override
  State<DailyDrawScreen> createState() => _DailyDrawScreenState();
}

class _DailyDrawScreenState extends State<DailyDrawScreen> {
  final List<String> _selectedDigits = ['', '', ''];
  int _multiplier = 1;
  static const int _ticketPrice = 60;
  final DrawModel _dailyDraw = DrawModel.sampleDraws[1];

  static const List<int> _multiplierPresets = [1, 2, 5, 10, 20];

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
              const Icon(Icons.info_outline_rounded, color: AppColors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                'Please select all 3 digits (000 - 999)',
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
          draw: _dailyDraw,
          selectedNumber: _selectedDigits.join(''),
          initialTicketCount: _multiplier,
          unitPrice: _ticketPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount = _ticketPrice * _multiplier;
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
          'Daily Draw',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tv_rounded, color: AppColors.greenAccent, size: 22),
            tooltip: 'Live Stream',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveDrawScreen(draw: _dailyDraw),
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
              // 1. Next Draw Banner Card with Live Countdown
              _buildDailyDrawHeroCard(),

              const SizedBox(height: 18),

              // 2. 3-Digit Selector Header & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT 3 DIGIT NUMBER (000 - 999)',
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

              // 4. Multiplier Chips (1x, 2x, 5x, 10x, 20x)
              _buildMultiplierChips(),

              const SizedBox(height: 16),

              // 5. 0-9 Keypad
              _buildKeypad(),

              const SizedBox(height: 16),

              // 6. Ticket Price and Multiplier Stepper Row
              _buildPriceAndStepperRow(totalAmount),

              const SizedBox(height: 16),

              // 7. BUY TICKET CTA (Green Emerald Gradient)
              TradexButton(
                text: 'BUY TICKET • ৳ $totalAmount',
                variant: TradexButtonVariant.secondaryGreen,
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
                        builder: (_) => LiveDrawScreen(draw: _dailyDraw),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm, color: AppColors.greenLight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Today 10:00 PM  •  Watch Live Draw',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.greenLight, size: 18),
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

  Widget _buildDailyDrawHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greenAccent.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenAccent.withValues(alpha: 0.1),
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
                'Next Draw Today',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '10:00 PM',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Jackpot Prize ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '৳ 50,000',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const DailyDrawTicketIcon(size: 60),
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
                  ? AppColors.greenAccent
                  : (isCurrentEmpty ? AppColors.greenLight.withValues(alpha: 0.7) : AppColors.cardBorder),
              width: isFilled ? 2.2 : (isCurrentEmpty ? 1.6 : 1),
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.greenAccent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isCurrentEmpty
                    ? [
                        BoxShadow(
                          color: AppColors.greenAccent.withValues(alpha: 0.15),
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

  Widget _buildMultiplierChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WINNING MULTIPLIER / TICKET COPIES',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _multiplierPresets.map((m) {
            final bool isSelected = _multiplier == m;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _multiplier = m);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.greenAccent.withValues(alpha: 0.2)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.greenAccent
                            : AppColors.cardBorder,
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${m}x',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.greenLight : AppColors.textSecondary,
                      ),
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
                        color: AppColors.greenAccent.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.casino_outlined, color: AppColors.greenLight, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Quick Pick',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenLight,
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
                  if (_multiplier > 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _multiplier--);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$_multiplier',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenLight,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  if (_multiplier < 100) {
                    HapticFeedback.selectionClick();
                    setState(() => _multiplier++);
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
