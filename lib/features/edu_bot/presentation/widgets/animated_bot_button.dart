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
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
              ? math.sin(_floatController.value * math.pi * 18) * 1.0  // Barely noticeable minimal offline shake
              : 0.0;
              
          final yOffset = math.sin(_floatController.value * math.pi) * 6;

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
    final glowColor = isOnline ? AppColors.primary.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6);

    // 3D Metallic silver body
    const metalGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFD1D8DD), Color(0xFF78909C)],
      stops: [0.0, 0.4, 1.0],
    );

    // Dark glass face
    const screenGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF263238), Color(0xFF0F171A)],
    );

    // Common 3D styling edge highlight
    final borderStyle = Border.all(color: Colors.white.withOpacity(0.8), width: 0.5);

    return SizedBox(
      width: 58,
      height: 75,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ambient Glow behind the robot
          Positioned(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 28, spreadRadius: -2)
                ]
              ),
            ),
          ),
          
          // ================= EARS =================
          Positioned(
            top: 15, left: 2,
            child: Container(
              width: 4, height: 10,
              decoration: BoxDecoration(color: const Color(0xFF78909C), borderRadius: BorderRadius.circular(2)),
            )
          ),
          Positioned(
            top: 15, right: 2,
            child: Container(
              width: 4, height: 10,
              decoration: BoxDecoration(color: const Color(0xFF78909C), borderRadius: BorderRadius.circular(2)),
            )
          ),

          // ================= ARMS =================
          Positioned(
            left: 3 + (math.sin(floatValue * math.pi) * 1.5),
            top: 32 + (math.cos(floatValue * math.pi * 2) * 2), // Inverse arm bobbing
            child: Transform.rotate(
              angle: 0.15,
              child: Container(
                width: 7, height: 20,
                decoration: BoxDecoration(
                  gradient: metalGradient,
                  borderRadius: BorderRadius.circular(4),
                  border: borderStyle,
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(-2, 3))]
                ),
              ),
            ),
          ),
          Positioned(
            right: 3 - (math.sin(floatValue * math.pi) * 1.5),
            top: 32 + (math.cos(floatValue * math.pi * 2) * 2), // Inverse arm bobbing
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                width: 7, height: 20,
                decoration: BoxDecoration(
                  gradient: metalGradient,
                  borderRadius: BorderRadius.circular(4),
                  border: borderStyle,
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 3))]
                ),
              ),
            ),
          ),

          // ================= LEGS =================
          Positioned(
            bottom: 2,
            left: 17,
            child: Container(
              width: 8, height: 12,
              decoration: BoxDecoration(
                gradient: metalGradient,
                borderRadius: BorderRadius.circular(4),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 2))]
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 17,
            child: Container(
              width: 8, height: 12,
              decoration: BoxDecoration(
                gradient: metalGradient,
                borderRadius: BorderRadius.circular(4),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 2))]
              ),
            ),
          ),
          
          // ================= NECK =================
          Positioned(
            top: 31,
            child: Container(
              width: 10, height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF37474F), // dark joint
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),

          // ================= BODY =================
          Positioned(
            bottom: 12,
            child: Container(
              width: 34, height: 26,
              decoration: BoxDecoration(
                gradient: metalGradient,
                borderRadius: BorderRadius.circular(10),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Center(
                // Core
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8, height: 8,
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
              width: 46, height: 32,
              decoration: BoxDecoration(
                gradient: metalGradient,
                borderRadius: BorderRadius.circular(14),
                border: borderStyle,
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Center(
                // Face Screen
                child: Container(
                  width: 36, height: 18,
                  decoration: BoxDecoration(
                    gradient: screenGradient,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // left eye
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8, height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: eyeColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: glowColor, blurRadius: 6)]
                        ),
                      ),
                      // right eye
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8, height: 10,
                        decoration: BoxDecoration(
                          color: eyeColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: glowColor, blurRadius: 6)]
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
