import 'package:flutter/material.dart';

class GlowingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double top;
  final double left;
  final double opacity;

  const GlowingOrb({
    super.key,
    required this.size,
    required this.color,
    required this.top,
    required this.left,
    this.opacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: size * 0.8,
              spreadRadius: size * 0.12,
            ),
          ],
        ),
      ),
    );
  }
}