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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
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
            final pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine).value;
            return Transform.scale(
              scale: 1.0 + (pulse * 0.03),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C1C21), Color(0xFF050608)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2 + (pulse * 0.15)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05 + (pulse * 0.05)),
                      blurRadius: 10 + (pulse * 6),
                      spreadRadius: pulse * 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
