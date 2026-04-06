import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AnimatedBotButton extends StatefulWidget {
  final VoidCallback onTap;

  const AnimatedBotButton({
    super.key, 
    required this.onTap,
  });

  @override
  State<AnimatedBotButton> createState() => _AnimatedBotButtonState();
}

class _AnimatedBotButtonState extends State<AnimatedBotButton> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pressController;
  
  bool _isOnline = true;
  Timer? _connectivityTimer;
  Timer? _blinkTimer;
  bool _isPressed = false;
  
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    // Very slow, subtle floating
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkConnectivity());
    _scheduleBlink();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pressController.dispose();
    _connectivityTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _scheduleBlink() {
    if (!mounted) return;
    final int delay = math.Random().nextInt(3000) + 3000;
    _blinkTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() => _isBlinking = false);
        _scheduleBlink();
      });
    });
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

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic)
    );

    return GestureDetector(
      onTapDown: (_) { setState(() => _isPressed = true); _pressController.forward(); },
      onTapUp: (_) { setState(() => _isPressed = false); _pressController.reverse(); widget.onTap(); },
      onTapCancel: () { setState(() => _isPressed = false); _pressController.reverse(); },
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _pressController]),
        builder: (context, child) {
          // Extremely subtle float
          double yOffset = math.sin(_floatController.value * math.pi) * 1.5; 

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, yOffset),
                  child: _MascotRobot(
                    isOnline: _isOnline, 
                    isBlinking: _isBlinking,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MascotRobot extends StatelessWidget {
  final bool isOnline;
  final bool isBlinking;

  const _MascotRobot({
    required this.isOnline, 
    required this.isBlinking,
  });

  @override
  Widget build(BuildContext context) {
    // Elegant, less intrusive color palette
    final eyeColor = isOnline ? AppColors.primary : Colors.white54;
    final glowColor = isOnline ? AppColors.primary.withOpacity(0.3) : Colors.transparent;

    // Cleaner, more premium solid dark feel rather than complex gradients
    const surfaceColor = Color(0xFF1E1E22);
    const borderColor = Color(0xFF2C2C32);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (glowColor != Colors.transparent)
            BoxShadow(
              color: glowColor,
              blurRadius: 16,
              spreadRadius: -4,
            ),
        ],
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // left eye
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 8, 
                height: isBlinking ? 2 : 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: eyeColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isBlinking ? [] : [BoxShadow(color: glowColor, blurRadius: 4)]
                ),
              ),
              // right eye
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 8, 
                height: isBlinking ? 2 : 10,
                decoration: BoxDecoration(
                  color: eyeColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isBlinking ? [] : [BoxShadow(color: glowColor, blurRadius: 4)]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

