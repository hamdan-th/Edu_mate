import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../data/specializations_data.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedCollege = collegesList.first;
  String _specializationId = '';
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _specializationId = specializationsList
        .firstWhere((item) => item.college == _selectedCollege)
        .id;
  }

  List<SpecializationItem> get _filteredSpecializations {
    return specializationsList
        .where((item) => item.college == _selectedCollege)
        .toList();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    super.dispose();
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
      animation: _floatAnimation,
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
                  color: AppColors.blueGlow.withOpacity(0.20),
                  blurRadius: 24,
                  spreadRadius: 1.5,
                ),
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.10),
                  blurRadius: 16,
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

  Future<bool> _isUsernameTaken(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username_lowercase', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final bio = _bioController.text.trim();
    final password = _passwordController.text.trim();

    final selectedItem = specializationsList.firstWhere(
          (item) => item.id == _specializationId,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final isTaken = await _isUsernameTaken(username);

      if (isTaken) {
        _showMessage('اسم المستخدم مستخدم بالفعل');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'username_lowercase': username.toLowerCase(),
        'fullName': fullName,
        'email': email,
        'bio': bio,
        'college': _selectedCollege,
        'specializationId': selectedItem.id,
        'specializationName': selectedItem.name,
        'role': 'student',
        'isDoctorVerified': false,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage('تم إنشاء الحساب بنجاح');

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mainNav',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'فشل إنشاء الحساب';

      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مستخدم بالفعل';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جدًا';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _darkInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    Color? iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: iconColor ?? AppColors.blueGlow),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputDarkFill,
      labelStyle: TextStyle(
        color: AppColors.textOnDark.withOpacity(0.72),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.textOnDark.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.blueGlow,
          width: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          _buildLogo(),
                          const SizedBox(height: 14),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أنشئ هويتك داخل Edu Mate وابدأ رحلتك',
                            style: TextStyle(
                              color: AppColors.textOnDark.withOpacity(0.74),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Card(
                            color: AppColors.darkSurface.withOpacity(0.94),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'Username',
                                      icon: Icons.alternate_email_rounded,
                                      iconColor: AppColors.blueGlow,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'أدخل اسم المستخدم';
                                      }
                                      if (text.length < 3) {
                                        return 'اسم المستخدم قصير جدًا';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9._]+$')
                                          .hasMatch(text)) {
                                        return 'يسمح فقط بالحروف والأرقام و . و _';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _fullNameController,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      iconColor: AppColors.blueGlow,
                                    ),
                                    validator: (value) {
                                      if ((value?.trim() ?? '').isEmpty) {
                                        return 'أدخل الاسم';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      iconColor: AppColors.secondary,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'أدخل البريد الإلكتروني';
                                      }
                                      if (!text.contains('@')) {
                                        return 'البريد الإلكتروني غير صالح';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCollege,
                                    dropdownColor: AppColors.inputDarkFill,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'الكلية',
                                      icon: Icons.account_balance_outlined,
                                      iconColor: AppColors.secondary,
                                    ),
                                    items: collegesList.map((college) {
                                      return DropdownMenuItem<String>(
                                        value: college,
                                        child: Text(college),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedCollege = value;
                                        _specializationId = specializationsList
                                            .firstWhere((item) =>
                                        item.college ==
                                            _selectedCollege)
                                            .id;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    value: _specializationId,
                                    dropdownColor: AppColors.inputDarkFill,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'التخصص',
                                      icon: Icons.school_outlined,
                                      iconColor: AppColors.blueGlow,
                                    ),
                                    items:
                                    _filteredSpecializations.map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item.id,
                                        child: Text(item.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _specializationId = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _bioController,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'نبذة تعريفية',
                                      icon: Icons.info_outline,
                                      iconColor: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      iconColor: AppColors.secondary,
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
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'أدخل كلمة المرور';
                                      }
                                      if (text.length < 6) {
                                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                      _isLoading ? null : _handleSignup,
                                      child: _isLoading
                                          ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color:
                                          AppColors.primaryDark,
                                        ),
                                      )
                                          : const Text('Create Account'),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'لديك حساب بالفعل؟ تسجيل الدخول',
                                      style: TextStyle(
                                        color: AppColors.blueGlow,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}