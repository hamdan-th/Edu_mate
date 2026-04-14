import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/premium_feedback.dart';
import '../settings/settings_bottom_sheet.dart';

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
  bool _isGuestLoading = false;

  late final AnimationController _entranceController;

  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;

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

  Future<void> _browseAsGuest() async {
    setState(() => _isGuestLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (!mounted) return;
      // Mark this session as guest in the provider
      context.read<GuestProvider>().setGuest(true);
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mainNav',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // 🔍 DEBUG: طباعة الخطأ الحقيقي في debug console
      // ignore: avoid_print
      print('[GuestLogin] FirebaseAuthException: code=${e.code} | message=${e.message}');
      if (mounted) {
        String msg = 'تعذّر الدخول كضيف.';
        if (e.code == 'operation-not-allowed') {
          msg = 'تسجيل الدخول كضيف غير مفعّل. يرجى التواصل مع المطوّر.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[GuestLogin] Unknown error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ غير متوقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
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
    // Explicitly watch settings provider to ensure instant UI updates for language/theme
    context.watch<AppSettingsProvider>();
    
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Premium Reactive Radial Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  colorScheme.surface,
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          
          // 2. Settings Toggle (Top Corner)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ScaleOnPress(
                  child: IconButton(
                    onPressed: () => SettingsBottomSheet.show(context),
                    icon: const Icon(
                      Icons.translate_rounded,
                      size: 24,
                    ),
                    tooltip: l10n.settings,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface.withOpacity(0.5),
                      foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      
                      // 1. Header Section - Logo with Reactive Glow
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.12),
                              blurRadius: 40,
                              spreadRadius: 8,
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
                            
                      const SizedBox(height: 24),
                            
                      Text(
                        l10n.app_name,
                        style: textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onBackground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.loginWelcomeBack,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                        
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
                                color: colorScheme.outline.withOpacity(0.2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.loginTitle,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.loginSubtitle,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // 4. Input Fields
                                  Column(
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
                                      const SizedBox(height: 14),
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
                                              color: colorScheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Secondary Elements -> Forgot Password
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ScaleOnPress(
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _resetPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.primary,
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          l10n.loginForgotPassword, 
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // 5. Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ScaleOnPress(
                                      onTap: _isLoading ? null : _handleLogin,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor: isDark ? Colors.black : Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: isDark ? Colors.black : Colors.white,
                                                ),
                                              )
                                            : Text(
                                                l10n.loginTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.loginNoAccount,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      ScaleOnPress(
                                        child: TextButton(
                                          onPressed: _goToSignup,
                                          style: TextButton.styleFrom(
                                            foregroundColor: colorScheme.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                          ),
                                          child: Text(
                                            l10n.loginSignupAction,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Browse as Guest button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ScaleOnPress(
                                      child: TextButton(
                                        onPressed: (_isLoading || _isGuestLoading)
                                            ? null
                                            : _browseAsGuest,
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        child: _isGuestLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                l10n.loginGuestAction,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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