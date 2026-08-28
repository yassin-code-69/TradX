import 'package:flutter/material.dart';
import 'package:tradex/theme/app_colors.dart';

class CustomCrown extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const CustomCrown({
    super.key,
    this.width = 24,
    this.height = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CrownPainter(color: color ?? AppColors.goldPrimary),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;

  _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFFFA000),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // Crown base bottom left
    path.moveTo(w * 0.15, h * 0.95);
    // Base bottom right
    path.lineTo(w * 0.85, h * 0.95);
    // Right point bottom
    path.lineTo(w * 0.95, h * 0.25);
    // Valley 2
    path.lineTo(w * 0.68, h * 0.65);
    // Center point peak
    path.lineTo(w * 0.50, h * 0.05);
    // Valley 1
    path.lineTo(w * 0.32, h * 0.65);
    // Left point peak
    path.lineTo(w * 0.05, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);

    // Draw little jewel spheres on top of the 3 main tips
    final Paint jewelPaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.05, h * 0.25), w * 0.05, jewelPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.05), w * 0.06, jewelPaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.25), w * 0.05, jewelPaint);

    // Crown base rim bar
    final Paint rimPaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.15, h * 0.85), Offset(w * 0.85, h * 0.85), rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
