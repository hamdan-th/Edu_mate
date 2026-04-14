import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/guest_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/upload_screening_service.dart';
import '../../services/registry_service.dart';
import '../../core/utils/user_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool _isUploadingImage = false;
  bool _isDeleting = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
  }


  Future<void> _pickAndUploadProfileImage() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      // Perform pre-upload screening
      await UploadScreeningService.validate(file, isImage: true);

      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': imageUrl,
      });
      final l10n = AppLocalizations.of(context)!;
      _showMessage(l10n.profileUpdatePhotoSuccess);
    } catch (e) {
      if (mounted && e is ScreeningException) {
        UploadScreeningService.showScanError(context, e);
      } else {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(l10n.profileUpdatePhotoFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }


  Future<void> _logout() async {
    try {
      setState(() {
        _isLoggingOut = true;
      });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showMessage(l10n.profileLogoutFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.profileDeleteAccount),
        content: Text(
          l10n.profileDeleteConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.profileCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.profileDelete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isDeleting = true;
      });

      final uid = user.uid;

      // 1) حذف الحساب من Firebase Auth أولًا
      await user.delete();

      // 2) إذا نجح حذف Auth نحذف بيانات Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 3) حذف صورة البروفايل إن وجدت
      try {
        await FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$uid.jpg')
            .delete();
      } catch (_) {}

      // 4) تنظيف الجلسة والعودة لصفحة الدخول
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (e.code == 'requires-recent-login') {
        _showMessage(l10n.profileDeleteRequiresLogin);
      } else {
        _showMessage(l10n.profileDeleteFailed);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showMessage(l10n.profileDeleteError);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _editBio(String currentBio) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentBio);
    
    final newBio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileBioLabel),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: InputDecoration(
            hintText: l10n.profileBioLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.profileCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.profileSave),
          ),
        ],
      ),
    );

    if (newBio != null && newBio != currentBio) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .update({'bio': newBio});
        _showMessage(l10n.profileUpdateSuccess);
      } catch (e) {
        _showMessage(l10n.profileUpdateFailed);
      }
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: isDark ? 0.45 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? colorScheme.primary).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (label == AppLocalizations.of(context)!.profileBioLabel)
            IconButton(
              onPressed: () => _editBio(value),
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String photoUrl, String username) {
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Text(
            firstLetter,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _isUploadingImage ? null : _pickAndUploadProfileImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.12), 
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isUploadingImage
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
                  : const Icon(
                Icons.photo_camera_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.profileNoUser),
        ),
      );
    }

    // 🚫 Guest profile state (Login button)
    if (context.read<GuestProvider>().isGuest) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle), elevation: 0, centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 24),
                Text(
                  'أنت الآن في وضع الضيف',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'سجل دخولك لتتمتع بكامل مميزات التطبيق مثل الإعجاب، التعليق، حفظ الملفات والدردشة مع الآخرين بمجموعاتك الأكاديمية.',
                  style: TextStyle(fontSize: 14.5, height: 1.6, color: isDark ? AppColors.textSecondary : Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 1. Sign out anonymous session
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      // 2. Head to login screen directly
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('تسجيل الدخول / إنشاء حساب', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withValues(alpha: isDark ? 0.55 : 0.25),
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        title: Text(l10n.profileTitle, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(l10n.profileNoData),
            );
          }

          final data = snapshot.data!.data()!;
          final username = data['username'] ?? '';
          final fullName = data['fullName'] ?? '';
          final email = data['email'] ?? '';
          final bio = data['bio'] ?? '';
          final college = data['college'] ?? '';
          final specializationName = data['specializationName'] ?? '';
          final photoUrl = data['photoUrl'] ?? '';
          final isDoctorVerified = data['isDoctorVerified'] == true;
          final role = data['role'] ?? 'student';
          final displayName = data['displayName'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: isDark ? 0.45 : 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileAvatar(photoUrl, username),
                      const SizedBox(height: 14),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            UserUtils.getDisplayName(data),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleLarge?.color,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (isDoctorVerified)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isDoctorVerified ? l10n.profileVerifiedDoc : l10n.profileUserRole.replaceAll('{role}', role),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  label: l10n.profileUsernameLabel,
                  value: username,
                ),
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: l10n.profileFullNameLabel,
                  value: fullName,
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: l10n.profileEmailLabel,
                  value: email,
                ),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  label: l10n.profileBioLabel,
                  value: bio,
                ),
                if (role != 'doctor') ...[
                  _buildInfoTile(
                    icon: Icons.account_balance_outlined,
                    label: l10n.profileCollegeLabel,
                    value: college,
                  ),
                  _buildInfoTile(
                    icon: Icons.school_outlined,
                    label: l10n.profileSpecialtyLabel,
                    value: specializationName,
                  ),
                ],
                const SizedBox(height: 10),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                    ),
                    icon: _isLoggingOut
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.logout_rounded, size: 20),
                    label: Text(l10n.profileLogout, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isDeleting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text(l10n.profileDeleteAccount, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}