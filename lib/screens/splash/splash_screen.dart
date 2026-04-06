import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _glowController;
  late final AnimationController _floatController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))..forward();

    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/authGate');
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F1115);
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Subtle soft glowing background aura
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gold.withOpacity(0.04 * _glowAnimation.value),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _entranceController,
                  _floatController,
                ]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Real university logo asset integration
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withOpacity(0.12),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: gold.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'LOGO\nMISSING',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: gold.withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 36),
                            const Text(
                              'Edu Mate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'AL JEEL AL JADEED UNIVERSITY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: gold.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أجيال واعدة',
                              style: TextStyle(
                                color: gold.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}