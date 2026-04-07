import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';

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
                const Positioned(
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
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
                            style: textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.signupSubtitle,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupUsernameHint,
                                      icon: Icons.alternate_email_rounded,
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
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupFullNameHint,
                                      icon: Icons.person_outline,
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
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.loginEmailHint,
                                      icon: Icons.email_outlined,
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
                                    initialValue: _selectedCollege,
                                    dropdownColor: isDark ? AppColors.inputDarkFill : Colors.white,
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupCollegeHint,
                                      icon: Icons.account_balance_outlined,
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
                                            .firstWhere((item) => item.college == _selectedCollege)
                                            .id;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    initialValue: _specializationId,
                                    dropdownColor: isDark ? AppColors.inputDarkFill : Colors.white,
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupMajorHint,
                                      icon: Icons.school_outlined,
                                    ),
                                    items: _filteredSpecializations.map((item) {
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
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupBioHint,
                                      icon: Icons.info_outline,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.loginPasswordHint,
                                      icon: Icons.lock_outline,
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
                                      onPressed: _isLoading ? null : _handleSignup,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
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
                                        color: AppColors.primary,
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
    );
  }
}