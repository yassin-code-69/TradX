import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

/// Glowing Gold Trophy Widget for Mega Draw
class MegaDrawTrophyIcon extends StatelessWidget {
  final double size;

  const MegaDrawTrophyIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.72, size * 0.72),
          painter: _TrophyPainter(),
        ),
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Outer glow sparkle
    final Paint sparklePaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;

    // Draw little star sparkles
    _drawSparkle(canvas, Offset(w * 0.15, h * 0.18), 3, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.85, h * 0.20), 4, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.75), 2.5, sparklePaint);

    // Trophy cup gradient
    final Paint goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFEE58),
          Color(0xFFFFCA28),
          Color(0xFFFFA000),
          Color(0xFFFF8F00),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Trophy Cup Body
    final Path cupPath = Path();
    cupPath.moveTo(w * 0.26, h * 0.20);
    cupPath.lineTo(w * 0.74, h * 0.20);
    cupPath.cubicTo(
      w * 0.74, h * 0.55,
      w * 0.62, h * 0.68,
      w * 0.50, h * 0.70,
    );
    cupPath.cubicTo(
      w * 0.38, h * 0.68,
      w * 0.26, h * 0.55,
      w * 0.26, h * 0.20,
    );
    cupPath.close();
    canvas.drawPath(cupPath, goldPaint);

    // Trophy Handles (Left & Right)
    final Paint handlePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Path leftHandle = Path();
    leftHandle.moveTo(w * 0.26, h * 0.26);
    leftHandle.cubicTo(w * 0.08, h * 0.26, w * 0.08, h * 0.52, w * 0.28, h * 0.52);
    canvas.drawPath(leftHandle, handlePaint);

    final Path rightHandle = Path();
    rightHandle.moveTo(w * 0.74, h * 0.26);
    rightHandle.cubicTo(w * 0.92, h * 0.26, w * 0.92, h * 0.52, w * 0.72, h * 0.52);
    canvas.drawPath(rightHandle, handlePaint);

    // Trophy Stem
    final Paint stemPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    final RRect stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.44, h * 0.68, w * 0.12, h * 0.15),
      const Radius.circular(2),
    );
    canvas.drawRRect(stem, stemPaint);

    // Trophy Base (2 tiered)
    final RRect baseTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.81, w * 0.30, h * 0.07),
      const Radius.circular(2),
    );
    canvas.drawRRect(baseTop, goldPaint);

    final RRect baseBottom = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.88, w * 0.52, h * 0.09),
      const Radius.circular(3),
    );
    canvas.drawRRect(baseBottom, goldPaint);

    // Highlight sheen
    final Paint sheenPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path sheen = Path();
    sheen.moveTo(w * 0.32, h * 0.26);
    sheen.cubicTo(w * 0.32, h * 0.46, w * 0.38, h * 0.58, w * 0.46, h * 0.63);
    canvas.drawPath(sheen, sheenPaint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path p = Path();
    p.moveTo(center.dx, center.dy - radius * 1.5);
    p.lineTo(center.dx + radius * 0.35, center.dy - radius * 0.35);
    p.lineTo(center.dx + radius * 1.5, center.dy);
    p.lineTo(center.dx + radius * 0.35, center.dy + radius * 0.35);
    p.lineTo(center.dx, center.dy + radius * 1.5);
    p.lineTo(center.dx - radius * 0.35, center.dy + radius * 0.35);
    p.lineTo(center.dx - radius * 1.5, center.dy);
    p.lineTo(center.dx - radius * 0.35, center.dy - radius * 0.35);
    p.close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glowing Green Ticket Icon Widget for Daily Draw
class DailyDrawTicketIcon extends StatelessWidget {
  final double size;

  const DailyDrawTicketIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0C2B1D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.greenAccent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenAccent.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _TicketGridPainter(),
        ),
      ),
    );
  }
}

class _TicketGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Green Ticket Card background
    final Paint cardPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00E676),
          Color(0xFF00B0FF),
          Color(0xFF10B981),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.90, h * 0.90),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, cardPaint);

    // Inner dark container for matrix
    final Paint innerPaint = Paint()
      ..color = const Color(0xFF064E3B)
      ..style = PaintingStyle.fill;

    final RRect innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76),
      const Radius.circular(6),
    );
    canvas.drawRRect(innerRRect, innerPaint);

    // Draw 3x3 Plus/Hash symbols in vibrant light green
    final Paint plusPaint = Paint()
      ..color = const Color(0xFF6EE7B7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double startX = w * 0.28;
    final double startY = h * 0.28;
    final double stepX = w * 0.22;
    final double stepY = h * 0.22;
    final double arm = w * 0.05;

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final double cx = startX + c * stepX;
        final double cy = startY + r * stepY;
        // Horizontal bar
        canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), plusPaint);
        // Vertical bar
        canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), plusPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glowing Purple Neon Clock Icon Widget for Hourly Draw
class HourlyDrawClockIcon extends StatelessWidget {
  final double size;

  const HourlyDrawClockIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF231538),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purpleAccent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleAccent.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.68, size * 0.68),
          painter: _NeonClockPainter(),
        ),
      ),
    );
  }
}

class _NeonClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w * 0.44;

    // Glowing rim
    final Paint rimPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFC084FC),
          Color(0xFFA855F7),
          Color(0xFF7C3AED),
          Color(0xFFE879F9),
          Color(0xFFC084FC),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, rimPaint);

    // Clock Face inner dark fill
    final Paint faceFill = Paint()
      ..color = const Color(0xFF190C28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 1.5, faceFill);

    // Tick markers at 12, 1, 2, ...
    final Paint tickPaint = Paint()
      ..color = const Color(0xFFD8B4FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final double angle = i * (math.pi / 6);
      final double innerR = (i % 3 == 0) ? radius * 0.72 : radius * 0.82;
      final double outerR = radius * 0.90;
      final Offset p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final Offset p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Hour hand (pointing to 10 o'clock)
    final Paint hourHand = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const double hourAngle = -math.pi * 0.65;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.48 * math.cos(hourAngle),
        center.dy + radius * 0.48 * math.sin(hourAngle),
      ),
      hourHand,
    );

    // Minute hand (pointing to 2 o'clock)
    final Paint minuteHand = Paint()
      ..color = const Color(0xFFE879F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const double minuteAngle = -math.pi * 0.25;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.68 * math.cos(minuteAngle),
        center.dy + radius * 0.68 * math.sin(minuteAngle),
      ),
      minuteHand,
    );

    // Center pin
    final Paint centerPin = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.8, centerPin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wallet Chest / Overflowing Coins Graphic with Purple Glow and '+' button
class WalletChestGraphic extends StatelessWidget {
  final VoidCallback? onAddTap;

  const WalletChestGraphic({super.key, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      height: 75,
      child: Stack(
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        children: [
          // Purple glow behind chest
          Positioned(
            right: 15,
            top: 10,
            child: Container(
              width: 60,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.55),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Treasure Chest / Wallet Vector Art
          Positioned(
            right: 18,
            top: 2,
            child: CustomPaint(
              size: const Size(64, 56),
              painter: _TreasureChestPainter(),
            ),
          ),
          // Plus button overlay
          Positioned(
            right: 0,
            bottom: 6,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6D28D9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: const Color(0xFFA78BFA),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureChestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Spilling gold coins
    final Paint coinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Paint coinRim = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void drawCoin(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, coinPaint);
      canvas.drawCircle(Offset(x, y), r, coinRim);
    }

    drawCoin(w * 0.72, h * 0.78, 6.0);
    drawCoin(w * 0.85, h * 0.70, 5.0);
    drawCoin(w * 0.62, h * 0.86, 5.5);
    drawCoin(w * 0.82, h * 0.88, 4.5);

    // Glowing Purple/Indigo Chest Body
    final Paint chestBodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF7C3AED),
          Color(0xFF5B21B6),
          Color(0xFF311068),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final RRect chestBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.42, w * 0.70, h * 0.48),
      const Radius.circular(7),
    );
    canvas.drawRRect(chestBody, chestBodyPaint);

    // Gold trim on chest body
    final Paint goldTrim = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(chestBody, goldTrim);

    // Chest open lid
    final Paint chestLidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF9333EA),
          Color(0xFF6B21A8),
          Color(0xFF4A0E4E),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Path lidPath = Path();
    lidPath.moveTo(w * 0.05, h * 0.42);
    lidPath.cubicTo(w * 0.08, h * 0.12, w * 0.78, h * 0.12, w * 0.81, h * 0.42);
    lidPath.close();
    canvas.drawPath(lidPath, chestLidPaint);
    canvas.drawPath(lidPath, goldTrim);

    // Inner gold radiance
    final Paint goldInterior = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0x00FFB300)],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.43, h * 0.40), radius: 18))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.43, h * 0.40), 16, goldInterior);

    // Coins peeking out
    drawCoin(w * 0.32, h * 0.38, 5.0);
    drawCoin(w * 0.45, h * 0.34, 6.0);
    drawCoin(w * 0.58, h * 0.38, 5.5);

    // Front lock clasp
    final RRect lockClasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.46, w * 0.12, h * 0.18),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      lockClasp,
      Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.54),
      1.5,
      Paint()..color = const Color(0xFF3E1F00)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
