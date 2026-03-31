import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool _isUploadingImage = false;
  bool _isSendingVerification = false;
  bool _isDeleting = false;
  bool _isLoggingOut = false;

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

      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': imageUrl,
      });

      _showMessage('تم تحديث صورة الملف الشخصي');
    } catch (e) {
      _showMessage('فشل رفع الصورة');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _sendDoctorVerificationRequest(
      Map<String, dynamic> userData,
      ) async {
    final user = currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isSendingVerification = true;
      });

      final existing = await FirebaseFirestore.instance
          .collection('doctor_verification_request')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showMessage('لديك طلب توثيق قيد المراجعة بالفعل');
        return;
      }

      await FirebaseFirestore.instance
          .collection('doctor_verification_request')
          .add({
        'userId': user.uid,
        'username': userData['username'] ?? '',
        'fullName': userData['fullName'] ?? '',
        'email': userData['email'] ?? '',
        'photoUrl': userData['photoUrl'] ?? '',
        'college': userData['college'] ?? '',
        'specializationName': userData['specializationName'] ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage('تم إرسال طلب التوثيق إلى الداشبورد');
    } catch (e) {
      _showMessage('فشل إرسال طلب التوثيق');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVerification = false;
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
      _showMessage('فشل تسجيل الخروج');
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد؟ سيتم حذف الحساب كاملًا من التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
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
      if (e.code == 'requires-recent-login') {
        _showMessage('لحذف الحساب يجب تسجيل الدخول من جديد ثم إعادة المحاولة');
      } else {
        _showMessage('فشل حذف الحساب');
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء حذف الحساب');
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
          backgroundColor: AppColors.primary.withOpacity(0.12),
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
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploadingImage
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryDark,
                ),
              )
                  : const Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('لا يوجد مستخدم مسجل دخول'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
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
            return const Center(
              child: Text('لم يتم العثور على بيانات الملف الشخصي'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
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
                            fullName.isEmpty ? username : fullName,
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isDoctorVerified)
                            const Icon(
                              Icons.verified,
                              color: Colors.lightBlueAccent,
                              size: 22,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: AppColors.textOnDark.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isDoctorVerified ? 'دكتور موثق' : 'مستخدم $role',
                          style: const TextStyle(
                            color: AppColors.textOnDark,
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
                  label: 'اسم المستخدم',
                  value: username,
                ),
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: 'الاسم الكامل',
                  value: fullName,
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: email,
                ),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  label: 'النبذة',
                  value: bio,
                ),
                _buildInfoTile(
                  icon: Icons.account_balance_outlined,
                  label: 'الكلية',
                  value: college,
                ),
                _buildInfoTile(
                  icon: Icons.school_outlined,
                  label: 'التخصص',
                  value: specializationName,
                ),
                const SizedBox(height: 10),
                if (!isDoctorVerified)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSendingVerification
                          ? null
                          : () => _sendDoctorVerificationRequest(data),
                      icon: _isSendingVerification
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDark,
                        ),
                      )
                          : const Icon(Icons.verified_outlined),
                      label: const Text('طلب توثيق دكتور'),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.logout),
                    label: const Text('تسجيل الخروج'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
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
                        : const Icon(Icons.delete_outline),
                    label: const Text('حذف الحساب'),
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