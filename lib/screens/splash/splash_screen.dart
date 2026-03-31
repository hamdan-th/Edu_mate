import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final AnimationController _floatController;
  late final AnimationController _orbitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const topBg = Color(0xFF14213D);
    const bottomBg = Color(0xFF1F3B73);
    const blueGlow = Color(0xFF60A5FA);
    const gold = Color(0xFFFACC15);
    const white = Color(0xFFF8FAFC);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topBg, bottomBg],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueGlow.withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(
                      color: blueGlow.withOpacity(0.20),
                      blurRadius: 120,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: -80,
              right: -20,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withOpacity(0.08),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.16),
                      blurRadius: 120,
                      spreadRadius: 18,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoController,
                    _glowController,
                    _floatController,
                    _orbitController,
                  ]),
                  builder: (context, _) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 170,
                                height: 170,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 128,
                                      height: 128,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(34),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF223B6A),
                                            Color(0xFF172B4D),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: white.withOpacity(0.10),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: blueGlow.withOpacity(
                                              0.28 * _glowAnimation.value,
                                            ),
                                            blurRadius: 34,
                                            spreadRadius: 3,
                                          ),
                                          BoxShadow(
                                            color: gold.withOpacity(
                                              0.14 * _glowAnimation.value,
                                            ),
                                            blurRadius: 28,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),

                                    Transform.rotate(
                                      angle: _orbitController.value * 6.28318,
                                      child: Container(
                                        width: 152,
                                        height: 152,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: blueGlow.withOpacity(0.28),
                                            width: 1.1,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: gold,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      top: 32,
                                      child: Icon(
                                        Icons.school_rounded,
                                        size: 34,
                                        color: gold.withOpacity(0.96),
                                      ),
                                    ),

                                    Positioned(
                                      bottom: 40,
                                      child: Container(
                                        width: 70,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                margin:
                                                const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color:
                                                  const Color(0xFFE2E8F0),
                                                  borderRadius:
                                                  BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 2,
                                              height: double.infinity,
                                              color:
                                              const Color(0xFFCBD5E1),
                                            ),
                                            Expanded(
                                              child: Container(
                                                margin:
                                                const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color:
                                                  const Color(0xFFE2E8F0),
                                                  borderRadius:
                                                  BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      right: 36,
                                      top: 38,
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: white.withOpacity(0.95),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 26),

                              const Text(
                                'Edu',
                                style: TextStyle(
                                  color: white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Smart Student Assistant',
                                style: TextStyle(
                                  color: blueGlow.withOpacity(0.98),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                'مرحبًا',
                                style: TextStyle(
                                  color: white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'منصتك التعليمية الذكية تبدأ هنا',
                                style: TextStyle(
                                  color: white.withOpacity(0.76),
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 34),

                              SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      gold),
                                  backgroundColor:
                                  white.withOpacity(0.10),
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

            Positioned(
              bottom: 26,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Powered by Edu',
                  style: TextStyle(
                    color: white.withOpacity(0.34),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}