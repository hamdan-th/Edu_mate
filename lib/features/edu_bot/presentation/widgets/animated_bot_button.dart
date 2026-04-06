import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AnimatedBotButton extends StatefulWidget {
  final VoidCallback onTap;
  final double screenWidth;
  final double screenHeight;

  const AnimatedBotButton({
    super.key, 
    required this.onTap,
    required this.screenWidth,
    required this.screenHeight,
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
  bool _isMinimized = false;

  double _x = 0;
  double _y = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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
    final int delay = math.Random().nextInt(3000) + 2500;
    _blinkTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 120), () {
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

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isMinimized) return;
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
      // Keep boundaries safe without arbitrary context lookups
      _x = _x.clamp(8.0, widget.screenWidth - 68.0);
      _y = _y.clamp(120.0, widget.screenHeight - 140.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && widget.screenWidth > 0) {
      _x = widget.screenWidth - 64; 
      _y = widget.screenHeight - 180; 
      _isInitialized = true;
    }

    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic)
    );

    return Positioned(
      left: _isMinimized ? widget.screenWidth - 56 : _x,
      top: _isMinimized ? widget.screenHeight - 140 : _y,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onTapDown: (_) { if(!_isMinimized){ setState(() => _isPressed = true); _pressController.forward(); } },
        onTapUp: (_) { if(!_isMinimized){ setState(() => _isPressed = false); _pressController.reverse(); widget.onTap(); } },
        onTapCancel: () { if(!_isMinimized){ setState(() => _isPressed = false); _pressController.reverse(); } },
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _pressController]),
          builder: (context, child) {
            double yOffset = math.sin(_floatController.value * math.pi) * 4;
            
            if (_isMinimized) {
              return Transform.translate(
                offset: Offset(0, yOffset),
                child: _MinimizedBubble(
                  isOnline: _isOnline,
                  onRestore: () => setState(() => _isMinimized = false),
                ),
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, yOffset),
                    child: _MascotRobot(
                      isOnline: _isOnline, 
                      floatValue: _floatController.value,
                      isBlinking: _isBlinking,
                    ),
                  ),
                ),
                // Minimize Icon
                Positioned(
                  top: yOffset - 6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => setState(() => _isMinimized = true),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0,2))],
                      ),
                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MinimizedBubble extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onRestore;

  const _MinimizedBubble({required this.isOnline, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.primary : Colors.redAccent;
    return GestureDetector(
      onTap: onRestore,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          shape: BoxShape.circle,
          border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Icon(Icons.auto_awesome_rounded, color: statusColor, size: 20),
        ),
      ),
    );
  }
}

class _MascotRobot extends StatelessWidget {
  final bool isOnline;
  final double floatValue;
  final bool isBlinking;

  const _MascotRobot({
    required this.isOnline, 
    required this.floatValue,
    required this.isBlinking,
  });

  @override
  Widget build(BuildContext context) {
    final eyeColor = isOnline ? AppColors.primary : Colors.redAccent;
    final glowColor = isOnline ? AppColors.primary.withOpacity(0.8) : Colors.redAccent.withOpacity(0.8);

    // Contrasting clear carbon/graphite surface against dark feed
    const carbonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF63636B), Color(0xFF2C2C32), Color(0xFF16161A)],
      stops: [0.0, 0.5, 1.0],
    );

    // Deep Face View
    const screenGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0A0C), Color(0xFF000000)],
    );

    // Stronger gold accents
    final goldBorder = Border.all(color: AppColors.primary.withOpacity(0.6), width: 0.5);

    return SizedBox(
      width: 52,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ambient Glow
          Positioned(
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: glowColor, blurRadius: 28, spreadRadius: 4)]
              ),
            ),
          ),
          
          // ================= SENSORS =================
          Positioned(
            top: 14, left: 3,
            child: Container(
              width: 6, height: 8,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            )
          ),
          Positioned(
            top: 14, right: 3,
            child: Container(
              width: 6, height: 8,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            )
          ),

          // ================= ARMS =================
          Positioned(
            left: 2 + (math.sin(floatValue * math.pi) * 1.5),
            top: 30 + (math.cos(floatValue * math.pi * 2) * 2), 
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 7, height: 20,
                decoration: BoxDecoration(
                  gradient: carbonGradient,
                  borderRadius: BorderRadius.circular(4),
                  border: goldBorder,
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(-2, 2))]
                ),
              ),
            ),
          ),
          Positioned(
            right: 2 - (math.sin(floatValue * math.pi) * 1.5),
            top: 30 + (math.cos(floatValue * math.pi * 2) * 2), 
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 7, height: 20,
                decoration: BoxDecoration(
                  gradient: carbonGradient,
                  borderRadius: BorderRadius.circular(4),
                  border: goldBorder,
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))]
                ),
              ),
            ),
          ),

          // ================= LEGS =================
          Positioned(
            bottom: 2, left: 16,
            child: Container(width: 6, height: 8, decoration: BoxDecoration(gradient: carbonGradient, borderRadius: BorderRadius.circular(3), border: goldBorder)),
          ),
          Positioned(
            bottom: 2, right: 16,
            child: Container(width: 6, height: 8, decoration: BoxDecoration(gradient: carbonGradient, borderRadius: BorderRadius.circular(3), border: goldBorder)),
          ),

          // ================= BODY =================
          Positioned(
            bottom: 10,
            child: Container(
              width: 30, height: 22,
              decoration: BoxDecoration(
                gradient: carbonGradient,
                borderRadius: BorderRadius.circular(10),
                border: goldBorder,
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Center(
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 8)]
                  ),
                ),
              ),
            ),
          ),

          // ================= NECK =================
          Positioned(top: 26, child: Container(width: 10, height: 6, color: Colors.black)),

          // ================= HEAD =================
          Positioned(
            top: 4,
            child: Container(
              width: 42, height: 28,
              decoration: BoxDecoration(
                gradient: carbonGradient,
                borderRadius: BorderRadius.circular(12),
                border: goldBorder,
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Center(
                // Screen Glass
                child: Container(
                  width: 32, height: 16,
                  decoration: BoxDecoration(
                    gradient: screenGradient,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // left eye
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        width: 7, 
                        height: isBlinking ? 1 : 9,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: eyeColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isBlinking ? [] : [BoxShadow(color: glowColor, blurRadius: 6)]
                        ),
                      ),
                      // right eye
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        width: 7, 
                        height: isBlinking ? 1 : 9,
                        decoration: BoxDecoration(
                          color: eyeColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isBlinking ? [] : [BoxShadow(color: glowColor, blurRadius: 6)]
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
