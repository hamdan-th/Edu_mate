import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../screens/bot_screen.dart';

class FloatingBotButton extends StatefulWidget {
  final String sourceScreen;
  final EdgeInsetsGeometry padding;

  const FloatingBotButton({
    super.key,
    required this.sourceScreen,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<FloatingBotButton> createState() => _FloatingBotButtonState();
}

class _FloatingBotButtonState extends State<FloatingBotButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openBot() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BotScreen(sourceScreen: widget.sourceScreen),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));
          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        onTap: _openBot,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16161A), // Dark charcoal base
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.4 + (_controller.value * 0.4)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.15 + (_controller.value * 0.2)),
                    blurRadius: 12 + (_controller.value * 8),
                    spreadRadius: 2 + (_controller.value * 3),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded, // Premium AI icon
                color: Color(0xFFD4AF37), // Gold accent
                size: 26,
              ),
            );
          }
        ),
      ),
    );
  }
}
