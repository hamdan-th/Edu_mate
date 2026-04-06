import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _univOpacity;
  late final Animation<double> _arabicOpacity;
  
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))..forward();

    _exitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );

    _univOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.65, 0.85, curve: Curves.easeIn)),
    );

    _arabicOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );

    _navigateWithExit();
  }

  Future<void> _navigateWithExit() async {
    // Keep splash visible for ~2.5s before exit begins
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    await _exitController.forward();
    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, '/authGate');
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F1115);
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: child,
          );
        },
        child: Stack(
          children: [

            
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Logo
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withOpacity(0.06),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/university_logo.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // 2. Edu Mate Title
                          Opacity(
                            opacity: _titleOpacity.value,
                            child: const Text(
                              'Edu Mate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // 3. University Line
                          Opacity(
                            opacity: _univOpacity.value,
                            child: Text(
                              'AL JEEL AL JADEED UNIVERSITY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: gold.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.8,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // 4. Arabic Tagline
                          Opacity(
                            opacity: _arabicOpacity.value,
                            child: Text(
                              'أجيال واعدة',
                              style: TextStyle(
                                color: gold.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}