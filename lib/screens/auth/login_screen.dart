import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';

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

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginController.text.trim();
    final password = _passwordController.text.trim();

    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(l10n.errEnterEmailPass);
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
      String message = l10n.errLoginFailed;

      switch (e.code) {
        case 'invalid-email':
          message = l10n.errInvalidEmail;
          break;
        case 'user-not-found':
          message = l10n.errAccountNotFound;
          break;
        case 'wrong-password':
          message = l10n.errWrongPassword;
          break;
        case 'invalid-credential':
          message = l10n.errInvalidCredentials;
          break;
        case 'user-disabled':
          message = l10n.errAccountDisabled;
          break;
        case 'too-many-requests':
          message = l10n.errTooManyRequests;
          break;
      }

      _showMessage(message);
    } catch (_) {
      _showMessage(l10n.errUnexpected);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _loginController.text.trim();

    if (email.isEmpty) {
      _showMessage(l10n.resetEnterEmailFirst);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage(l10n.resetLinkSent);
    } on FirebaseAuthException catch (e) {
      String message = l10n.resetFailedSend;

      if (e.code == 'invalid-email') {
        message = l10n.errInvalidEmail;
      } else if (e.code == 'user-not-found') {
        message = l10n.resetEmailNotRegistered;
      }

      _showMessage(message);
    } catch (_) {
      _showMessage(l10n.errUnexpected);
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // 1. Header Section - Logo
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
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
                        
                  const SizedBox(height: 36), // Increased spacing
                        
                        Text(
                          l10n.app_name,
                          style: textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginWelcomeBack,
                          style: textTheme.bodyMedium,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 3. Login Card with Entrance Animation
                        SlideTransition(
                          position: _cardSlide,
                          child: FadeTransition(
                            opacity: _cardOpacity,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? AppColors.border.withOpacity(0.5) : Colors.black12,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.loginTitle,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.loginSubtitle,
                                      style: TextStyle(
                                        color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    
                                    // 4. Input Fields
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme: InputDecorationTheme(
                                          fillColor: isDark ? AppColors.inputDarkFill : const Color(0xFFF3F4F6),
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                          labelStyle: TextStyle(
                                            color: isDark ? Colors.white.withOpacity(0.4) : Colors.black54,
                                          ),
                                          prefixIconColor: AppColors.primary.withOpacity(0.8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: isDark ? AppColors.border.withOpacity(0.2) : Colors.black12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 2.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _loginController,
                                            keyboardType: TextInputType.emailAddress,
                                            style: textTheme.bodyLarge,
                                            decoration: _inputDecoration(
                                              label: l10n.loginEmailHint,
                                              icon: Icons.person_outline_rounded,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            style: textTheme.bodyLarge,
                                            decoration: _inputDecoration(
                                              label: l10n.loginPasswordHint,
                                              icon: Icons.lock_outline_rounded,
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(() => _obscurePassword = !_obscurePassword);
                                                },
                                                icon: Icon(
                                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                  color: isDark ? AppColors.textSecondary : Colors.black54,
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
                                          foregroundColor: isDark ? Colors.white.withOpacity(0.6) : Colors.black54, 
                                        ),
                                        child: Text(l10n.loginForgotPassword, style: const TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // 5. Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(l10n.loginTitle),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.loginNoAccount,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _goToSignup,
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                          ),
                                          child: Text(
                                            l10n.loginSignupAction,
                                            style: const TextStyle(
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
          ),
        );
  }
}