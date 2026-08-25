import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/theme/app_colors.dart';

class MegaDrawInfoScreen extends StatelessWidget {
  const MegaDrawInfoScreen({super.key});

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
          'Mega Draw Info',
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Banner Card: "How Mega Draw Works?" + Glowing Purple 3D '?'
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.purpleAccent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How Mega Draw Works?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buy your tickets between 2nd to 30th of each month. The lucky winner will be announced on 1st of every month.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Glowing 3D Question Mark Graphic
                    const _GlowingPurpleQuestionGraphic(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Key Information Section Header
              Text(
                'Key Information',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Key Information Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Draw Date',
                      value: '1st of Every Month',
                    ),
                    const Divider(color: AppColors.divider, height: 18),
                    _buildInfoRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Ticket Sale Period',
                      value: '2nd - 30th of Every Month',
                    ),
                    const Divider(color: AppColors.divider, height: 18),
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Draw Time',
                      value: '09:00 PM',
                    ),
                    const Divider(color: AppColors.divider, height: 18),
                    _buildInfoRow(
                      icon: Icons.emoji_events_outlined,
                      label: 'Prize',
                      value: '৳ 5,00,000',
                      valueColor: AppColors.goldAccent,
                    ),
                    const Divider(color: AppColors.divider, height: 18),
                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Winners',
                      value: '1 Winner',
                    ),
                    const Divider(color: AppColors.divider, height: 18),
                    _buildInfoRow(
                      icon: Icons.sell_outlined,
                      label: 'Ticket Price',
                      value: '৳ 100 per Ticket',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Bottom Promo Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MegaDrawScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.purpleAccent.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'More tickets, more chances!',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'All tickets have equal chances to win.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 3D Gift box icon with purple glow
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF231538),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.purpleAccent.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: AppColors.purpleLight,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Custom 3D Glowing Purple Question Mark Graphic
class _GlowingPurpleQuestionGraphic extends StatelessWidget {
  const _GlowingPurpleQuestionGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // 3D Question mark vector
          CustomPaint(
            size: const Size(40, 48),
            painter: _QuestionMarkPainter(),
          ),
        ],
      ),
    );
  }
}

class _QuestionMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Glowing 3D Purple Gradient
    final Paint glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE879F9),
          Color(0xFFC084FC),
          Color(0xFFA855F7),
          Color(0xFF7E22CE),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Question Mark Curve
    final Path curvePath = Path();
    curvePath.moveTo(w * 0.28, h * 0.25);
    curvePath.cubicTo(
      w * 0.28, h * 0.05,
      w * 0.85, h * 0.05,
      w * 0.82, h * 0.32,
    );
    curvePath.cubicTo(
      w * 0.80, h * 0.48,
      w * 0.50, h * 0.52,
      w * 0.50, h * 0.68,
    );

    canvas.drawPath(curvePath, glowPaint);

    // Specular highlight on curve
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path highlightPath = Path();
    highlightPath.moveTo(w * 0.36, h * 0.16);
    highlightPath.cubicTo(
      w * 0.42, h * 0.09,
      w * 0.72, h * 0.09,
      w * 0.75, h * 0.22,
    );
    canvas.drawPath(highlightPath, highlightPaint);

    // Bottom Dot of question mark
    final Paint dotPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF5D0FE),
          Color(0xFFA855F7),
          Color(0xFF6B21A8),
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.50, h * 0.88), radius: 4.5))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.50, h * 0.88), 4.2, dotPaint);

    // Dot specular highlight
    canvas.drawCircle(
      Offset(w * 0.47, h * 0.85),
      1.2,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
