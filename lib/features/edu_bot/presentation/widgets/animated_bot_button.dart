import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AnimatedBotButton extends StatefulWidget {
  final VoidCallback onTap;

  const AnimatedBotButton({super.key, required this.onTap});

  @override
  State<AnimatedBotButton> createState() => _AnimatedBotButtonState();
}

class _AnimatedBotButtonState extends State<AnimatedBotButton> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pressController;
  
  bool _isOnline = true;
  Timer? _connectivityTimer;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pressController.dispose();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    bool hasInternet = true;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        hasInternet = false;
      }
    } on SocketException catch (_) {
      hasInternet = false;
    }
    
    if (mounted && hasInternet != _isOnline) {
      setState(() {
        _isOnline = hasInternet;
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic)
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _pressController]),
        builder: (context, child) {
          final yOffset = math.sin(_floatController.value * math.pi) * 5;

          return Transform.scale(
            scale: scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, yOffset),
              child: _BotCharacter(isOnline: _isOnline),
            ),
          );
        },
      ),
    );
  }
}

class _BotCharacter extends StatelessWidget {
  final bool isOnline;

  const _BotCharacter({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.primary : Colors.redAccent.withOpacity(0.8);
    final glowOpacity = isOnline ? 0.20 : 0.08;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          // Ambient dynamic glow based on network state
          BoxShadow(
            color: statusColor.withOpacity(glowOpacity),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          // Structural dark drop shadow for float priority
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          child: Icon(
            Icons.auto_awesome_rounded, // Premium implicit Spark / AI icon
            color: statusColor,
            size: 26,
          ),
        ),
      ),
    );
  }
}
