import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 1. Nagad Logo & Badge
class NagadLogo extends StatelessWidget {
  final double iconSize;
  final double? fontSize;
  final bool showText;
  final Color textColor;

  const NagadLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize,
    this.showText = true,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NagadBadgeIcon(size: iconSize),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'নগদ',
            style: GoogleFonts.hindSiliguri(
              fontSize: fontSize ?? 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ],
    );
  }
}

class NagadBadgeIcon extends StatelessWidget {
  final double size;

  const NagadBadgeIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final double width = size * 1.15;
    final double height = size * 0.85;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF97316), // Vivid Orange
            Color(0xFFEA580C), // Deep Orange
            Color(0xFFDC2626), // Red Accent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(width * 0.7, height * 0.7),
          painter: _NagadIconPainter(),
        ),
      ),
    );
  }
}

class _NagadIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw stylized 'নগদ' / swirl motif
    final Path swirlPath = Path();
    swirlPath.moveTo(w * 0.15, h * 0.50);
    swirlPath.cubicTo(w * 0.15, h * 0.15, w * 0.50, h * 0.15, w * 0.65, h * 0.35);
    swirlPath.cubicTo(w * 0.80, h * 0.55, w * 0.70, h * 0.85, w * 0.45, h * 0.85);
    swirlPath.cubicTo(w * 0.25, h * 0.85, w * 0.20, h * 0.65, w * 0.35, h * 0.55);
    swirlPath.cubicTo(w * 0.45, h * 0.48, w * 0.58, h * 0.55, w * 0.52, h * 0.65);
    swirlPath.cubicTo(w * 0.48, h * 0.70, w * 0.40, h * 0.68, w * 0.38, h * 0.62);

    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(swirlPath, strokePaint);

    // Decorative inner dot
    canvas.drawCircle(Offset(w * 0.75, h * 0.32), 1.8, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. bKash Logo & Badge (Origami Bird)
class BKashLogo extends StatelessWidget {
  final double iconSize;
  final double? fontSize;
  final bool showText;
  final Color textColor;

  const BKashLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize,
    this.showText = true,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BKashBadgeIcon(size: iconSize),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'বিকাশ',
            style: GoogleFonts.hindSiliguri(
              fontSize: fontSize ?? 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ],
    );
  }
}

class BKashBadgeIcon extends StatelessWidget {
  final double size;

  const BKashBadgeIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE2136E), // bKash Pink
            Color(0xFFC2185B), // Deep bKash Pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2136E).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _BKashBirdPainter(),
        ),
      ),
    );
  }
}

class _BKashBirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // bKash iconic origami bird facets
    // Wing 1 (top wing angled up-right)
    final Path topWing = Path();
    topWing.moveTo(w * 0.48, h * 0.44);
    topWing.lineTo(w * 0.88, h * 0.08);
    topWing.lineTo(w * 0.68, h * 0.44);
    topWing.close();
    canvas.drawPath(topWing, whitePaint);

    // Head and Beak (pointing up-left)
    final Path head = Path();
    head.moveTo(w * 0.48, h * 0.44);
    head.lineTo(w * 0.22, h * 0.22);
    head.lineTo(w * 0.12, h * 0.32);
    head.lineTo(w * 0.38, h * 0.52);
    head.close();
    canvas.drawPath(head, whitePaint);

    // Body triangle
    final Path body = Path();
    body.moveTo(w * 0.38, h * 0.52);
    body.lineTo(w * 0.68, h * 0.44);
    body.lineTo(w * 0.48, h * 0.76);
    body.close();
    canvas.drawPath(body, whitePaint);

    // Tail facet (down-left)
    final Path tail = Path();
    tail.moveTo(w * 0.48, h * 0.76);
    tail.lineTo(w * 0.26, h * 0.88);
    tail.lineTo(w * 0.38, h * 0.62);
    tail.close();
    canvas.drawPath(tail, whitePaint);

    // Wing fold shadow line
    final Paint linePaint = Paint()
      ..color = const Color(0xFFC2185B).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(w * 0.48, h * 0.44), Offset(w * 0.48, h * 0.76), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Rocket Logo & Badge (DBBL Rocket)
class RocketLogo extends StatelessWidget {
  final double iconSize;
  final double? fontSize;
  final bool showText;
  final Color textColor;

  const RocketLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize,
    this.showText = true,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RocketBadgeIcon(size: iconSize),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'Rocket',
            style: GoogleFonts.inter(
              fontSize: fontSize ?? 15.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ],
    );
  }
}

class RocketBadgeIcon extends StatelessWidget {
  final double size;

  const RocketBadgeIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9C27B0), // Rocket Purple
            Color(0xFF7B1FA2), // Deep Purple
            Color(0xFF6A1B9A), // Indigo Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C3494).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _RocketIconPainter(),
        ),
      ),
    );
  }
}

class _RocketIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Rocket tilted diagonally (pointing to top right)
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(math.pi / 4);

    // Rocket Nose & Body (centered)
    final Path rocketBody = Path();
    rocketBody.moveTo(0, -h * 0.42);
    rocketBody.cubicTo(w * 0.22, -h * 0.20, w * 0.22, h * 0.15, w * 0.18, h * 0.25);
    rocketBody.lineTo(-w * 0.18, h * 0.25);
    rocketBody.cubicTo(-w * 0.22, h * 0.15, -w * 0.22, -h * 0.20, 0, -h * 0.42);
    rocketBody.close();
    canvas.drawPath(rocketBody, whitePaint);

    // Left Fin
    final Path leftFin = Path();
    leftFin.moveTo(-w * 0.18, h * 0.10);
    leftFin.lineTo(-w * 0.38, h * 0.32);
    leftFin.lineTo(-w * 0.16, h * 0.28);
    leftFin.close();
    canvas.drawPath(leftFin, whitePaint);

    // Right Fin
    final Path rightFin = Path();
    rightFin.moveTo(w * 0.18, h * 0.10);
    rightFin.lineTo(w * 0.38, h * 0.32);
    rightFin.lineTo(w * 0.16, h * 0.28);
    rightFin.close();
    canvas.drawPath(rightFin, whitePaint);

    // Rocket Porthole Window
    final Paint windowPaint = Paint()
      ..color = const Color(0xFF7B1FA2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -h * 0.05), w * 0.09, windowPaint);

    // Rocket Jet Thruster Flame
    final Paint flamePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    final Path flame = Path();
    flame.moveTo(-w * 0.10, h * 0.25);
    flame.lineTo(0, h * 0.44);
    flame.lineTo(w * 0.10, h * 0.25);
    flame.close();
    canvas.drawPath(flame, flamePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
