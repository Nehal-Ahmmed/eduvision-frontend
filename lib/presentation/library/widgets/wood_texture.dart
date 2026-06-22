import 'package:flutter/material.dart';

class WoodTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base wood color
    final Paint basePaint = Paint()..color = const Color(0xFFDCA86A); // Warm wooden color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Draw vertical grain lines
    final Paint grainPaint = Paint()
      ..color = const Color(0xFFC78F49) // Slightly darker
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Use a fixed pseudo-random pattern to keep it deterministic but realistic
    final List<double> gaps = [2, 4, 1, 3, 5, 2, 6, 1, 3, 2];
    double x = 0;
    int index = 0;

    while (x < size.width) {
      // Add slight opacity variation based on index
      grainPaint.color = Color(0xFFC78F49).withOpacity(0.3 + (index % 3) * 0.1);
      
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        grainPaint,
      );
      
      x += gaps[index % gaps.length];
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WoodBackground extends StatelessWidget {
  final Widget child;
  const WoodBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WoodTexturePainter(),
      child: child,
    );
  }
}
