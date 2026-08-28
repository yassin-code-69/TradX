import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.size = 58,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.goldPrimary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _AvatarPainter(),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Background circle: Warm golden cream gradient
    final Paint bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFD54F)],
        center: Alignment(0.0, -0.2),
        radius: 0.8,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // Body / Shirt (Dark Amber / Brown shirt)
    final Paint shirtPaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.fill;
    final Path shirtPath = Path();
    shirtPath.moveTo(w * 0.15, h);
    shirtPath.quadraticBezierTo(w * 0.20, h * 0.76, w * 0.38, h * 0.78);
    shirtPath.lineTo(w * 0.50, h * 0.88);
    shirtPath.lineTo(w * 0.62, h * 0.78);
    shirtPath.quadraticBezierTo(w * 0.80, h * 0.76, w * 0.85, h);
    shirtPath.close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Collar / Inner Shirt
    final Paint collarPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    final Path collar = Path();
    collar.moveTo(w * 0.38, h * 0.78);
    collar.lineTo(w * 0.50, h * 0.88);
    collar.lineTo(w * 0.62, h * 0.78);
    collar.lineTo(w * 0.50, h * 0.74);
    collar.close();
    canvas.drawPath(collar, collarPaint);

    // Neck
    final Paint skinPaint = Paint()
      ..color = const Color(0xFFFFCC80)
      ..style = PaintingStyle.fill;
    final RRect neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.42, h * 0.62, w * 0.16, h * 0.18),
      const Radius.circular(4),
    );
    canvas.drawRRect(neck, skinPaint);

    // Face Shape (Warm skin)
    final Path facePath = Path();
    facePath.moveTo(w * 0.30, h * 0.35);
    facePath.quadraticBezierTo(w * 0.30, h * 0.68, w * 0.50, h * 0.74);
    facePath.quadraticBezierTo(w * 0.70, h * 0.68, w * 0.70, h * 0.35);
    facePath.quadraticBezierTo(w * 0.70, h * 0.22, w * 0.50, h * 0.22);
    facePath.quadraticBezierTo(w * 0.30, h * 0.22, w * 0.30, h * 0.35);
    facePath.close();
    canvas.drawPath(facePath, skinPaint);

    // Ears
    canvas.drawCircle(Offset(w * 0.28, h * 0.44), w * 0.05, skinPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.44), w * 0.05, skinPaint);

    // Hair (Dark Brown / Charcoal Modern pompadour)
    final Paint hairPaint = Paint()
      ..color = const Color(0xFF2E1A11)
      ..style = PaintingStyle.fill;
    final Path hairPath = Path();
    hairPath.moveTo(w * 0.27, h * 0.36);
    hairPath.quadraticBezierTo(w * 0.24, h * 0.14, w * 0.50, h * 0.12);
    hairPath.quadraticBezierTo(w * 0.76, h * 0.14, w * 0.73, h * 0.36);
    hairPath.quadraticBezierTo(w * 0.60, h * 0.22, w * 0.50, h * 0.24);
    hairPath.quadraticBezierTo(w * 0.40, h * 0.22, w * 0.27, h * 0.36);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // Beard & Mustache (Dark Charcoal/Brown full beard)
    final Path beardPath = Path();
    beardPath.moveTo(w * 0.30, h * 0.46);
    beardPath.quadraticBezierTo(w * 0.30, h * 0.74, w * 0.50, h * 0.76);
    beardPath.quadraticBezierTo(w * 0.70, h * 0.74, w * 0.70, h * 0.46);
    beardPath.lineTo(w * 0.65, h * 0.46);
    beardPath.quadraticBezierTo(w * 0.63, h * 0.64, w * 0.50, h * 0.67);
    beardPath.quadraticBezierTo(w * 0.37, h * 0.64, w * 0.35, h * 0.46);
    beardPath.close();
    canvas.drawPath(beardPath, hairPaint);

    // Mustache
    final Path mustache = Path();
    mustache.moveTo(w * 0.36, h * 0.54);
    mustache.quadraticBezierTo(w * 0.50, h * 0.51, w * 0.64, h * 0.54);
    mustache.quadraticBezierTo(w * 0.50, h * 0.62, w * 0.36, h * 0.54);
    mustache.close();
    canvas.drawPath(mustache, hairPaint);

    // Sunglasses / Glasses (Black Frame with subtle reflection)
    final Paint framePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final Paint bridgePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Bridge between eyes
    canvas.drawLine(Offset(w * 0.46, h * 0.41), Offset(w * 0.54, h * 0.41), bridgePaint);

    // Left lens
    final RRect leftLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.36, w * 0.13, h * 0.11),
      const Radius.circular(4),
    );
    canvas.drawRRect(leftLens, framePaint);

    // Right lens
    final RRect rightLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.53, h * 0.36, w * 0.13, h * 0.11),
      const Radius.circular(4),
    );
    canvas.drawRRect(rightLens, framePaint);

    // Reflection sheen on sunglasses
    final Paint sheen = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.36, h * 0.44), Offset(w * 0.42, h * 0.38), sheen);
    canvas.drawLine(Offset(w * 0.55, h * 0.44), Offset(w * 0.61, h * 0.38), sheen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
