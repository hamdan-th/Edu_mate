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
      duration: const Duration(milliseconds: 3000),
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
          final isRestless = !_isOnline;
          final shake = isRestless 
              ? math.sin(_floatController.value * math.pi * 18) * 1.0 
              : 0.0;
              
          final yOffset = math.sin(_floatController.value * math.pi) * 5;

          return Transform.scale(
            scale: scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(shake, yOffset),
              child: _MascotRobot(isOnline: _isOnline, floatValue: _floatController.value),
            ),
          );
        },
      ),
    );
  }
}

class _MascotRobot extends StatelessWidget {
  final bool isOnline;
  final double floatValue;

  const _MascotRobot({required this.isOnline, required this.floatValue});

  @override
  Widget build(BuildContext context) {
    final eyeColor = isOnline ? AppColors.primary : Colors.redAccent;
    final glowColor = isOnline ? AppColors.primary.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5);

    // Dark Graphite Body matching Premium Identity
    const darkBodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A3A3D), Color(0xFF1C1C1E), Color(0xFF101013)],
      stops: [0.0, 0.4, 1.0],
    );

    // Deep void screen for the face
    const screenGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C0C0E), Color(0xFF1A1A1E)],
    );

    // Minimal gold accent outline
    final borderStyle = Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5);
    final coreBorderStyle = Border.all(color: Colors.white.withOpacity(0.03), width: 1);

    return SizedBox(
      width: 48,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ambient Glow behind the robot
          Positioned(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 20, spreadRadius: 2)
                ]
              ),
            ),
          ),
          
          // ================= SENSORS / EARS =================
          Positioned(
            top: 10, left: 3,
            child: Container(
              width: 4, height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.8), // gold accent sensor
                borderRadius: BorderRadius.circular(2),
              ),
            )
          ),
          Positioned(
            top: 10, right: 3,
            child: Container(
              width: 4, height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.8), // gold accent sensor
                borderRadius: BorderRadius.circular(2),
              ),
            )
          ),

          // ================= ARMS =================
          Positioned(
            left: 2 + (math.sin(floatValue * math.pi) * 1.5),
            top: 26 + (math.cos(floatValue * math.pi * 2) * 2), // Inverse arm bobbing
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 6, height: 18,
                decoration: BoxDecoration(
                  gradient: darkBodyGradient,
                  borderRadius: BorderRadius.circular(3),
                  border: borderStyle,
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(-2, 2))]
                ),
              ),
            ),
          ),
          Positioned(
            right: 2 - (math.sin(floatValue * math.pi) * 1.5),
            top: 26 + (math.cos(floatValue * math.pi * 2) * 2), // Inverse arm bobbing
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 6, height: 18,
                decoration: BoxDecoration(
                  gradient: darkBodyGradient,
                  borderRadius: BorderRadius.circular(3),
                  border: borderStyle,
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))]
                ),
              ),
            ),
          ),

          // ================= LEGS =================
          Positioned(
            bottom: 0,
            left: 14,
            child: Container(
              width: 6, height: 10,
              decoration: BoxDecoration(
                gradient: darkBodyGradient,
                borderRadius: BorderRadius.circular(3),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 2))]
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 14,
            child: Container(
              width: 6, height: 10,
              decoration: BoxDecoration(
                gradient: darkBodyGradient,
                borderRadius: BorderRadius.circular(3),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 2))]
              ),
            ),
          ),

          // ================= NECK =================
          Positioned(
            top: 26,
            child: Container(
              width: 8, height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF111113), // dark joint
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.9),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),

          // ================= BODY =================
          Positioned(
            bottom: 10,
            child: Container(
              width: 28, height: 22,
              decoration: BoxDecoration(
                gradient: darkBodyGradient,
                borderRadius: BorderRadius.circular(8),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Center(
                // Core
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: eyeColor, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: glowColor, blurRadius: 6)]
                  ),
                ),
              ),
            ),
          ),

          // ================= HEAD =================
          Positioned(
            top: 4,
            child: Container(
              width: 38, height: 26,
              decoration: BoxDecoration(
                gradient: darkBodyGradient,
                borderRadius: BorderRadius.circular(12),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Center(
                // Face Screen
                child: Container(
                  width: 28, height: 14,
                  decoration: BoxDecoration(
                    gradient: screenGradient,
                    borderRadius: BorderRadius.circular(5),
                    border: coreBorderStyle, // subtle internal edge
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // left eye
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 7, height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: eyeColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [BoxShadow(color: glowColor, blurRadius: 5)]
                        ),
                      ),
                      // right eye
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 7, height: 8,
                        decoration: BoxDecoration(
                          color: eyeColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [BoxShadow(color: glowColor, blurRadius: 5)]
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
