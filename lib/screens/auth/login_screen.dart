import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _floatController;
  late final AnimationController _glowController;

  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('أدخل البريد الإلكتروني وكلمة المرور');
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
      String message = 'فشل تسجيل الدخول';

      switch (e.code) {
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صالح';
          break;
        case 'user-not-found':
          message = 'هذا الحساب غير موجود';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-credential':
          message = 'بيانات الدخول غير صحيحة';
          break;
        case 'user-disabled':
          message = 'تم تعطيل هذا الحساب';
          break;
        case 'too-many-requests':
          message = 'محاولات كثيرة، حاول لاحقًا';
          break;
      }

      _showMessage(message);
    } catch (_) {
      _showMessage('حدث خطأ غير متوقع');
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
      _showMessage('أدخل البريد الإلكتروني أولاً');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
    } on FirebaseAuthException catch (e) {
      String message = 'فشل إرسال رابط إعادة التعيين';

      if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
      } else if (e.code == 'user-not-found') {
        message = 'هذا البريد غير مسجل';
      }

      _showMessage(message);
    } catch (_) {
      _showMessage('حدث خطأ غير متوقع');
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
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _glowController]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueGlow
                      .withOpacity(0.22 * _glowAnimation.value),
                  blurRadius: 26,
                  spreadRadius: 1.5,
                ),
                BoxShadow(
                  color: AppColors.secondary
                      .withOpacity(0.12 * _glowAnimation.value),
                  blurRadius: 18,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 22,
                  child: Icon(
                    Icons.school_rounded,
                    size: 30,
                    color: AppColors.secondary,
                  ),
                ),
                Positioned(
                  bottom: 18,
                  child: Container(
                    width: 56,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        Container(
                          width: 1.5,
                          color: const Color(0xFFCBD5E1),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 24,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.textOnDark.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              AppColors.primaryDark,
              Color(0xFF1E3A70),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blueGlow.withOpacity(0.10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blueGlow.withOpacity(0.18),
                        blurRadius: 100,
                        spreadRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -70,
                right: -25,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withOpacity(0.07),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.14),
                        blurRadius: 100,
                        spreadRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 20),
                        const Text(
                          'Edu Mate',
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            color: AppColors.textOnDark.withOpacity(0.82),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Card(
                          color: AppColors.darkSurface.withOpacity(0.94),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    color: AppColors.textOnDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ادخل بياناتك للوصول إلى منصتك التعليمية',
                                  style: TextStyle(
                                    color:
                                    AppColors.textOnDark.withOpacity(0.70),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme: Theme.of(context)
                                        .inputDecorationTheme
                                        .copyWith(
                                      fillColor: AppColors.inputDarkFill,
                                      labelStyle: TextStyle(
                                        color: AppColors.textOnDark
                                            .withOpacity(0.72),
                                      ),
                                      prefixIconColor:
                                      AppColors.blueGlow,
                                      enabledBorder:
                                      OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: AppColors.textOnDark
                                              .withOpacity(0.06),
                                        ),
                                      ),
                                      focusedBorder:
                                      OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(18),
                                        borderSide: const BorderSide(
                                          color: AppColors.blueGlow,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _loginController,
                                        keyboardType:
                                        TextInputType.emailAddress,
                                        style: const TextStyle(
                                          color: AppColors.textOnDark,
                                        ),
                                        decoration: _inputDecoration(
                                          label: 'Email',
                                          icon: Icons.person_outline,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                          color: AppColors.textOnDark,
                                        ),
                                        decoration: _inputDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_outline,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textOnDark
                                                  .withOpacity(0.70),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _resetPassword,
                                    child: const Text('نسيت كلمة المرور؟'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                    _isLoading ? null : _handleLogin,
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.primaryDark,
                                      ),
                                    )
                                        : const Text('Log In'),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'ليس لديك حساب؟',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textOnDark
                                            .withOpacity(0.75),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _goToSignup,
                                      child: const Text(
                                        'إنشاء حساب',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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