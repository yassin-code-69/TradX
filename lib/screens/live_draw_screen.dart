import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/draw_icons.dart';

class LiveDrawScreen extends StatefulWidget {
  final DrawModel draw;

  const LiveDrawScreen({super.key, required this.draw});

  @override
  State<LiveDrawScreen> createState() => _LiveDrawScreenState();
}

class _LiveDrawScreenState extends State<LiveDrawScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<String> _rollingDigits = [];
  bool _isDrawing = true;
  Timer? _rollTimer;
  int _viewers = 1420;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    for (int i = 0; i < widget.draw.totalDigits; i++) {
      _rollingDigits.add(_rnd.nextInt(10).toString());
    }

    _rollTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_isDrawing) {
        setState(() {
          for (int i = 0; i < _rollingDigits.length; i++) {
            _rollingDigits[i] = _rnd.nextInt(10).toString();
          }
          if (_rnd.nextBool()) {
            _viewers += _rnd.nextInt(5) - 2;
          }
        });
      }
    });

    // Stop rolling after 4.5 seconds to simulate draw result announcement
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() {
          _isDrawing = false;
          _animController.stop();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _rollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Live Draw',
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
            children: [
              // Top Live Badge & Viewers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.redAccent),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE NOW',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.redAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$_viewers watching',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hero Draw Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.draw.accentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.draw.accentColor.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDrawIcon(widget.draw.type),
                    const SizedBox(height: 12),
                    Text(
                      widget.draw.title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jackpot Prize',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.draw.prize,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: widget.draw.accentColor,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Digits Container
                    Text(
                      _isDrawing ? 'ROLLING WINNING NUMBERS...' : 'WINNING NUMBER DRAWN!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isDrawing ? AppColors.textGold : AppColors.greenLight,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(_rollingDigits.length, (index) {
                        return Container(
                          width: widget.draw.totalDigits > 4 ? 38 : 52,
                          height: widget.draw.totalDigits > 4 ? 44 : 58,
                          decoration: BoxDecoration(
                            color: AppColors.cardBgElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isDrawing
                                  ? widget.draw.accentColor
                                  : AppColors.greenAccent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isDrawing
                                        ? widget.draw.accentColor
                                        : AppColors.greenAccent)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _rollingDigits[index],
                            style: GoogleFonts.inter(
                              fontSize: widget.draw.totalDigits > 4 ? 20 : 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Live Status Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Event Schedule',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This draw is cryptographically verified and certified with guaranteed fairness. Winnings are credited immediately to winner wallets.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!_isDrawing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'RETURN TO HOME',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
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

  Widget _buildDrawIcon(DrawType type) {
    switch (type) {
      case DrawType.mega:
        return const MegaDrawTrophyIcon(size: 64);
      case DrawType.daily:
        return const DailyDrawTicketIcon(size: 64);
      case DrawType.hourly:
        return const HourlyDrawClockIcon(size: 64);
    }
  }
}
