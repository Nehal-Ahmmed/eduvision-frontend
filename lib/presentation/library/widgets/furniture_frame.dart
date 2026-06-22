import 'package:flutter/material.dart';

class FurnitureFrame extends StatelessWidget {
  final Widget child;

  const FurnitureFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          // Deep heavy drop shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 40,
            offset: const Offset(20, 30),
            spreadRadius: 8,
          ),
          // Sharp ground shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FramePainter(),
        child: Padding(
          padding: const EdgeInsets.all(28.0), // Thickness of the wooden frame
          child: Container(
            // The darkest inner recess gap between frame and backboard
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1A0C00), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 10,
                  offset: Offset(0, 0),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double t = 28.0; // Frame thickness
    final w = size.width;
    final h = size.height;

    // Draw base dark background to prevent any anti-aliasing pixel gaps between paths
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF2A1502));

    // TOP PANEL (Gradient from top edge to bottom edge)
    Path topPath = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(w - t, t)..lineTo(t, t)..close();
    Paint topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFDE0B4), // very bright highlight on upper edge
          Color(0xFFDCA86A),
          Color(0xFFB37327),
          Color(0xFF8B5115), // inner shadow edge
        ],
        stops: [0.0, 0.2, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, t));
    canvas.drawPath(topPath, topPaint);

    // BOTTOM PANEL (Gradient from top edge to bottom edge)
    Path bottomPath = Path()..moveTo(0, h)..lineTo(w, h)..lineTo(w - t, h - t)..lineTo(t, h - t)..close();
    Paint bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF331801), // inner dark shadow from recess
          Color(0xFF4A2505),
          Color(0xFF6B3A0A),
          Color(0xFF2A1502), // very dark bottom edge
        ],
        stops: [0.0, 0.3, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, h - t, w, t));
    canvas.drawPath(bottomPath, bottomPaint);

    // LEFT PANEL (Gradient from left edge to right edge)
    Path leftPath = Path()..moveTo(0, 0)..lineTo(t, t)..lineTo(t, h - t)..lineTo(0, h)..close();
    Paint leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFE6A665), // outer highlight
          Color(0xFFC4863A),
          Color(0xFF8B5115),
          Color(0xFF5A3108), // inner shadow
        ],
        stops: [0.0, 0.2, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, t, h));
    canvas.drawPath(leftPath, leftPaint);

    // RIGHT PANEL (Gradient from left edge to right edge)
    Path rightPath = Path()..moveTo(w, 0)..lineTo(w - t, t)..lineTo(w - t, h - t)..lineTo(w, h)..close();
    Paint rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF2A1502), // inner recess shadow
          Color(0xFF4A2505),
          Color(0xFF7A4211), // slight ambient light bounce
          Color(0xFF331801), // outer dark edge
        ],
        stops: [0.0, 0.2, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(w - t, 0, t, h));
    canvas.drawPath(rightPath, rightPaint);

    // --- High Fidelity Details ---

    // Outer Edge Highlight (top and left) - gives the wood a sharp lacquered corner
    canvas.drawLine(const Offset(0, 0), Offset(w, 0), Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 1.5);
    canvas.drawLine(const Offset(0, 0), Offset(0, h), Paint()..color = Colors.white.withOpacity(0.3)..strokeWidth = 1.5);

    // Outer Edge Shadow (bottom and right)
    canvas.drawLine(Offset(0, h), Offset(w, h), Paint()..color = Colors.black87..strokeWidth = 2);
    canvas.drawLine(Offset(w, 0), Offset(w, h), Paint()..color = Colors.black87..strokeWidth = 2);

    // Inner Miter Joints (The 4 diagonal cuts connecting the panels)
    final Paint miterPaint = Paint()..color = Colors.black.withOpacity(0.4)..strokeWidth = 1.0;
    final Paint miterHighlight = Paint()..color = Colors.white.withOpacity(0.1)..strokeWidth = 1.0;
    
    // Top-Left miter
    canvas.drawLine(const Offset(0, 0), Offset(t, t), miterPaint);
    canvas.drawLine(const Offset(1, 0), Offset(t + 1, t), miterHighlight); // adjacent highlight
    // Top-Right miter
    canvas.drawLine(Offset(w, 0), Offset(w - t, t), miterPaint);
    // Bottom-Left miter
    canvas.drawLine(Offset(0, h), Offset(t, h - t), miterPaint);
    // Bottom-Right miter
    canvas.drawLine(Offset(w, h), Offset(w - t, h - t), miterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
