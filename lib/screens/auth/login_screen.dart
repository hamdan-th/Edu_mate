import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _glowController;

  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mainNav',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-not-found':
          message = 'Account not found';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-credential':
          message = 'Invalid credentials';
          break;
        case 'user-disabled':
          message = 'Account disabled';
          break;
        case 'too-many-requests':
          message = 'Too many requests, try again later';
          break;
      }

      _showMessage(message);
    } catch (_) {
      _showMessage('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _loginController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Password reset link sent to your email');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset link';

      if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-not-found') {
        message = 'Email not registered';
      }

      _showMessage(message);
    } catch (_) {
      _showMessage('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToSignup() {
    Navigator.pushNamed(context, '/signup');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.darkSurface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle background glow
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, _) {
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.03 * _glowAnimation.value),
                              blurRadius: 120,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // 1. Header Section - Logo
                        AnimatedBuilder(
                          animation: Listenable.merge([_floatController, _glowController]),
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.08 * _glowAnimation.value),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/university_logo.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 36), // Increased spacing
                        
                        // Header Text
                        const Text(
                          'Edu Mate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 3. Login Card with Entrance Animation
                        SlideTransition(
                          position: _cardSlide,
                          child: FadeTransition(
                            opacity: _cardOpacity,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Log In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Sign in to access your platform',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    
                                    // 4. Input Fields
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme: InputDecorationTheme(
                                          fillColor: AppColors.inputDarkFill,
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                          labelStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.4), // improved placeholder contrast
                                          ),
                                          prefixIconColor: AppColors.primary.withOpacity(0.6), // reduced opacity
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: AppColors.border.withOpacity(0.2),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2.0, // stronger gold border
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _loginController,
                                            keyboardType: TextInputType.emailAddress,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: _inputDecoration(
                                              label: 'Email',
                                              icon: Icons.person_outline_rounded,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: _inputDecoration(
                                              label: 'Password',
                                              icon: Icons.lock_outline_rounded,
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword = !_obscurePassword;
                                                  });
                                                },
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_off_outlined
                                                      : Icons.visibility_outlined,
                                                  color: Colors.white.withOpacity(0.4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Secondary Elements -> Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _resetPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white.withOpacity(0.4), // subtle
                                        ),
                                        child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // 5. Login Button
                                    Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE8C868), // Soft lighter gold
                                            AppColors.primary, // Base gold
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.5),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: AppColors.secondary, // Dark text
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: AppColors.secondary,
                                                ),
                                              )
                                            : const Text(
                                                'Log In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _goToSignup,
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                          ),
                                          child: const Text(
                                            'Sign up',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}