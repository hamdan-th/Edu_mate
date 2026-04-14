import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/premium_feedback.dart';
import '../../data/specializations_data.dart';
import '../settings/settings_bottom_sheet.dart';

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
  String _accountType = 'student';
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

    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
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
          child: Image.asset(
            'assets/images/university_logo.png',
            width: 84,
            height: 84,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  Future<bool> _isUsernameTaken(String username) async {
    final doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();

    return doc.exists;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final bio = _bioController.text.trim();
    final password = _passwordController.text.trim();

    SpecializationItem? selectedItem;
    if (_accountType == 'student') {
      selectedItem = specializationsList.firstWhere(
            (item) => item.id == _specializationId,
        orElse: () => specializationsList.first,
      );
    }

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

      final userData = <String, dynamic>{
        'uid': uid,
        'username': username,
        'username_lowercase': username.toLowerCase(),
        'fullName': fullName,
        'email': email,
        'bio': bio,
        'role': _accountType,
        'isDoctorVerified': false,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_accountType == 'student' && selectedItem != null) {
        userData['college'] = _selectedCollege;
        userData['specializationId'] = selectedItem.id;
        userData['specializationName'] = selectedItem.name;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      final usernameRef = FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase());

      final usernameSnap = await usernameRef.get();
      if (usernameSnap.exists) {
        throw Exception('Username already taken');
      }

      await usernameRef.set({'uid': uid});

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
    required ColorScheme colorScheme,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

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

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        
                        // Header Section - Logo with Reactive Glow
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
                          child: _buildLogo(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          l10n.signupTitle,
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onBackground,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.signupSubtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // 3. Signup Card
                        Container(
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
                                TextFormField(
                                  controller: _usernameController,
                                  style: textTheme.bodyLarge,
                                  decoration: _inputDecoration(
                                    label: l10n.signupUsernameHint,
                                    icon: Icons.alternate_email_rounded,
                                    colorScheme: colorScheme,
                                  ),
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return l10n.errEmptyUsername;
                                    }
                                    if (text.length < 3) {
                                      return l10n.errShortUsername;
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(text)) {
                                      return l10n.errInvalidUsername;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _fullNameController,
                                  style: textTheme.bodyLarge,
                                  decoration: _inputDecoration(
                                    label: l10n.signupFullNameHint,
                                    icon: Icons.person_outline,
                                    colorScheme: colorScheme,
                                  ),
                                  validator: (value) {
                                    if ((value?.trim() ?? '').isEmpty) {
                                      return l10n.errEmptyName;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: textTheme.bodyLarge,
                                  decoration: _inputDecoration(
                                    label: l10n.loginEmailHint,
                                    icon: Icons.email_outlined,
                                    colorScheme: colorScheme,
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
                                const SizedBox(height: 12),
                                
                                // Account Type Switcher
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _AccountTypeOption(
                                          title: l10n.signupRoleStudent,
                                          isSelected: _accountType == 'student',
                                          onTap: () => setState(() => _accountType = 'student'),
                                        ),
                                      ),
                                      Expanded(
                                        child: _AccountTypeOption(
                                          title: l10n.signupRoleDoctor,
                                          isSelected: _accountType == 'doctor',
                                          onTap: () => setState(() => _accountType = 'doctor'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (_accountType == 'student') ...[
                                  const SizedBox(height: 18),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCollege,
                                    dropdownColor: colorScheme.surface,
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupCollegeHint,
                                      icon: Icons.account_balance_outlined,
                                      colorScheme: colorScheme,
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
                                  const SizedBox(height: 18),
                                  DropdownButtonFormField<String>(
                                    value: _specializationId,
                                    dropdownColor: colorScheme.surface,
                                    style: textTheme.bodyLarge,
                                    decoration: _inputDecoration(
                                      label: l10n.signupMajorHint,
                                      icon: Icons.school_outlined,
                                      colorScheme: colorScheme,
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
                                ],
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _bioController,
                                  maxLines: 2,
                                  style: textTheme.bodyLarge,
                                  decoration: _inputDecoration(
                                    label: l10n.signupBioHint,
                                    icon: Icons.info_outline,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: textTheme.bodyLarge,
                                  decoration: _inputDecoration(
                                    label: l10n.loginPasswordHint,
                                    icon: Icons.lock_outline,
                                    colorScheme: colorScheme,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: colorScheme.onSurface.withOpacity(0.5),
                                        size: 20,
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
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ScaleOnPress(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleSignup,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              l10n.signupBtn,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                    ),
                                    child: Text(
                                      l10n.signupAlreadyHaveAccount,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
          ),

          // 3. Settings Toggle (Top Corner - Layered over content for hit-testing)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SignupTopActionButton(
                  icon: Icons.translate_rounded,
                  onTap: () => SettingsBottomSheet.show(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reused proven account type option widget
class _AccountTypeOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Reused proven action button implementation from feed_screen.dart
class SignupTopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SignupTopActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface.withOpacity(0.98) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.textPrimary : Colors.black87,
          size: 20,
        ),
      ),
    );
  }
}