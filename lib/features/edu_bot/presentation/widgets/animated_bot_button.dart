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
    _connectivityTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkConnectivity());
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
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic)
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _pressController]),
        builder: (context, child) {
          // Warning shake if offline
          final shake = !_isOnline 
              ? math.sin(_floatController.value * math.pi * 12) * 1.5 
              : 0.0;
          
          final yOffset = math.sin(_floatController.value * math.pi) * 6;

          return Transform.scale(
            scale: scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(shake, yOffset),
              child: _BotCharacter(isOnline: _isOnline, floatValue: _floatController.value),
            ),
          );
        },
      ),
    );
  }
}

class _BotCharacter extends StatelessWidget {
  final bool isOnline;
  final double floatValue;

  const _BotCharacter({required this.isOnline, required this.floatValue});

  @override
  Widget build(BuildContext context) {
    final eyeColor = isOnline ? AppColors.primary : Colors.redAccent;
    final glowColor = isOnline ? AppColors.primary.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5);

    return Container(
      width: 54,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isOnline ? AppColors.primary.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Antenna base
          Positioned(
            top: -4,
            child: Container(
              width: 12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
          // Antenna stem
          Positioned(
            top: -10,
            child: Container(
              width: 3,
              height: 6,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          // Antenna bulb
          Positioned(
            top: -14,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: eyeColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: glowColor, blurRadius: 4)],
              ),
            ),
          ),
          
          // Face Screen
          Positioned(
            top: 12,
            child: Container(
              width: 38,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F13), // Deep void screen
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black.withOpacity(0.6), width: 1.5),
              ),
              child: Stack(
                children: [
                  // Left Eye
                  Positioned(
                    left: 8,
                    top: 5,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 5,
                      height: 7,
                      decoration: BoxDecoration(
                        color: eyeColor,
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [BoxShadow(color: glowColor, blurRadius: 4)],
                      ),
                    ),
                  ),
                  // Right Eye
                  Positioned(
                    right: 8,
                    top: 5,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 5,
                      height: 7,
                      decoration: BoxDecoration(
                        color: eyeColor,
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [BoxShadow(color: glowColor, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Body details
          Positioned(
            bottom: 12,
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 10,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          
          // Left Floating Arm
          Positioned(
            left: -6,
            top: 24 + math.sin(floatValue * math.pi) * 4,
            child: Container(
              width: 5,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Right Floating Arm
          Positioned(
            right: -6,
            top: 24 + math.sin(floatValue * math.pi) * 4,
            child: Container(
              width: 5,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
