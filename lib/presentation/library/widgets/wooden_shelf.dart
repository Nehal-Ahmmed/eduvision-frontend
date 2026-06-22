import 'package:flutter/material.dart';

class WoodenShelf extends StatelessWidget {
  final List<Widget> books;
  final double width;

  const WoodenShelf({
    super.key,
    required this.books,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Books Row
        SizedBox(
          height: 160,
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: books,
          ),
        ),
        // The Physical Shelf
        Container(
          width: width,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE6A665), // Highlight on top edge
                Color(0xFFC4863A), // Main shelf top
                Color(0xFF8B5115), // Front edge starts
                Color(0xFF5A3108), // Front edge bottom
              ],
              stops: [0.0, 0.2, 0.21, 1.0],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 16,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
            border: const Border(
              left: BorderSide(color: Color(0xFF9E5C23), width: 4),
              right: BorderSide(color: Color(0xFF4A2505), width: 4),
              bottom: BorderSide(color: Color(0xFF331801), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
