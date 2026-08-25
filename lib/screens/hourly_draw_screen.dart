import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/live_draw_screen.dart';
import 'package:tradex/screens/payment_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/draw_icons.dart';

class HourlyDrawScreen extends StatefulWidget {
  const HourlyDrawScreen({super.key});

  @override
  State<HourlyDrawScreen> createState() => _HourlyDrawScreenState();
}

class _HourlyDrawScreenState extends State<HourlyDrawScreen> {
  final List<String> _selectedDigits = ['', '', ''];
  int _ticketCount = 1;
  static const int _ticketPrice = 20;

  int _secondsRemaining = 18 * 60 + 42;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
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
    setState(() {
      for (int i = _selectedDigits.length - 1; i >= 0; i--) {
        if (_selectedDigits[i].isNotEmpty) {
          _selectedDigits[i] = '';
          break;
        }
      }
    });
  }

  void _onQuickPick() {
    final random = math.Random();
    setState(() {
      for (int i = 0; i < _selectedDigits.length; i++) {
        _selectedDigits[i] = random.nextInt(10).toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount = _ticketPrice * _ticketCount;
    final bool isNumberComplete = _selectedDigits.every((d) => d.isNotEmpty);

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
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Next Draw Countdown Banner Card
              Container(
                padding: const EdgeInsets.all(16),
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
                          'Next Draw In',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'HOUR    ',
                              style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'MIN    ',
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
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '৳ 20,000',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.purpleAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const HourlyDrawClockIcon(size: 56),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: SELECT YOUR 3 DIGIT NUMBER
              Text(
                'SELECT YOUR 3 DIGIT NUMBER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 14),

              // 3 Digit Display Circles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final String digit = _selectedDigits[index];
                  final bool isFilled = digit.isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.cardBgElevated : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? AppColors.purpleAccent : AppColors.cardBorderHighlight,
                        width: 2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppColors.purpleAccent.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      digit,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Number Keypad
              _buildKeypad(),

              const SizedBox(height: 18),

              // Ticket Price and Quantity Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Price',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '৳ $_ticketPrice',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Tickets',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () {
                                if (_ticketCount > 1) {
                                  setState(() => _ticketCount--);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$_ticketCount',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () {
                                setState(() => _ticketCount++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pay and Confirm Button (Crimson / Magenta Wine Gradient)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD81B60), // Vibrant Crimson Magenta
                      Color(0xFFAD1457), // Deep Wine Magenta
                      Color(0xFF880E4F), // Dark Wine
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAD1457).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (!isNumberComplete) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select all 3 digits'),
                          backgroundColor: AppColors.cardBgElevated,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          draw: DrawModel.sampleDraws[2],
                          selectedNumber: _selectedDigits.join(''),
                          ticketCount: _ticketCount,
                          ticketPrice: _ticketPrice,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'PAY ৳ $totalAmount & CONFIRM',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Live Draw Link (Navigates to LiveDrawScreen)
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveDrawScreen(draw: DrawModel.sampleDraws[2]),
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
                          'Every Hour  •  Live Draw',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['1', '2', '3'].map((d) => _buildKey(d)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['4', '5', '6'].map((d) => _buildKey(d)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['7', '8', '9'].map((d) => _buildKey(d)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _onQuickPick,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Quick Pick',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purpleLight,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildKey('0'),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
