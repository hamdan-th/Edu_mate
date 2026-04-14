import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  
  // Staggered Animations for Logo, Title, and Subtitle
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Background deepens (0.0 - 0.4)
    _backgroundOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // 2. Logo entrance with spring-back effect (0.1 - 0.6)
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.5, curve: Curves.easeIn),
    );

    // 3. Title entrance (0.4 - 0.8)
    _titleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );
    _titleSlide = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // 4. University Subtitle entrance (0.6 - 1.0)
    _subtitleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _mainController.forward();
    // Maintain presentation before navigation
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    
    // Smooth transition to the /authGate
    Navigator.pushReplacementNamed(context, '/authGate');
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Premium Radial Gradient Background for Depth
          AnimatedBuilder(
            animation: _backgroundOpacity,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      AppColors.surface.withOpacity(_backgroundOpacity.value),
                      AppColors.background,
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Hero Content Layout
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with scale, fade, and subtle glow
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1 * _logoOpacity.value),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/university_logo.png',
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // App Name Title
                AnimatedBuilder(
                  animation: _titleOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: const Text(
                          'Edu Mate',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Official Al Jeel Al Jadeed University Identity
                AnimatedBuilder(
                  animation: _subtitleOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _subtitleOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            'AL JEEL AL JADEED UNIVERSITY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'أجيال واعدة',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}