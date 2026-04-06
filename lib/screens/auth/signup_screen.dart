import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context)!;

      if (isTaken) {
        _showMessage(l10n.errUsernameTaken);
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

      _showMessage(l10n.signupSuccess);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mainNav',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.signupFailed;

      if (e.code == 'email-already-in-use') {
        message = l10n.errEmailAlreadyInUse;
      } else if (e.code == 'invalid-email') {
        message = l10n.errInvalidEmail;
      } else if (e.code == 'weak-password') {
        message = l10n.errWeakPassword;
      }

      _showMessage(message);
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showMessage(l10n.errUnexpected);
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
    required bool isDark,
    Widget? suffixIcon,
    Color? iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: iconColor ?? AppColors.blueGlow),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.inputDarkFill : const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: isDark ? AppColors.textOnDark.withOpacity(0.72) : Colors.black54,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? AppColors.textOnDark.withOpacity(0.06) : Colors.black12,
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
              ? const [
                  AppColors.primaryDark,
                  Color(0xFF1E3A70),
                ]
              : [
                  const Color(0xFFF9FAFB), 
                  const Color(0xFFF3F4F6)
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
                          Text(
                            l10n.signupTitle,
                            style: TextStyle(
                              color: isDark ? AppColors.textOnDark : Colors.black87,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.signupSubtitle,
                            style: TextStyle(
                              color: isDark ? AppColors.textOnDark.withOpacity(0.74) : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Card(
                            color: isDark ? AppColors.darkSurface.withOpacity(0.94) : colorScheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.signupUsernameHint,
                                      icon: Icons.alternate_email_rounded,
                                      iconColor: AppColors.blueGlow,
                                      isDark: isDark,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return l10n.errEmptyUsername;
                                      }
                                      if (text.length < 3) {
                                        return l10n.errShortUsername;
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9._]+$')
                                          .hasMatch(text)) {
                                        return l10n.errInvalidUsername;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _fullNameController,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.signupFullNameHint,
                                      icon: Icons.person_outline,
                                      iconColor: AppColors.blueGlow,
                                      isDark: isDark,
                                    ),
                                    validator: (value) {
                                      if ((value?.trim() ?? '').isEmpty) {
                                        return l10n.errEmptyName;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.loginEmailHint,
                                      icon: Icons.email_outlined,
                                      iconColor: AppColors.secondary,
                                      isDark: isDark,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return l10n.errEmptyEmail;
                                      }
                                      if (!text.contains('@')) {
                                        return l10n.errInvalidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCollege,
                                    dropdownColor: isDark ? AppColors.inputDarkFill : Colors.white,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.signupCollegeHint,
                                      icon: Icons.account_balance_outlined,
                                      iconColor: AppColors.secondary,
                                      isDark: isDark,
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
                                    dropdownColor: isDark ? AppColors.inputDarkFill : Colors.white,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.signupMajorHint,
                                      icon: Icons.school_outlined,
                                      iconColor: AppColors.blueGlow,
                                      isDark: isDark,
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
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.signupBioHint,
                                      icon: Icons.info_outline,
                                      iconColor: AppColors.secondary,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textOnDark : Colors.black87,
                                    ),
                                    decoration: _darkInputDecoration(
                                      label: l10n.loginPasswordHint,
                                      icon: Icons.lock_outline,
                                      iconColor: AppColors.secondary,
                                      isDark: isDark,
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
                                          color: isDark 
                                              ? AppColors.textOnDark.withOpacity(0.70)
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return l10n.errEmptyPassword;
                                      }
                                      if (text.length < 6) {
                                        return l10n.errShortPassword;
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
                                          : Text(l10n.signupBtn),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      l10n.signupAlreadyHaveAccount,
                                      style: const TextStyle(
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