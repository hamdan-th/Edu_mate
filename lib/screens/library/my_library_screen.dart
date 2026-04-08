import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'library_files_service.dart';
import 'library_theme.dart';
import 'my_files_list_screen.dart';
import 'upload_screen.dart';

class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  Stream<int> _collectionGroupCount(String collectionName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collectionGroup(collectionName)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _combinedReferencesCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return Stream<int>.multi((controller) {
      Set<String> normalIds = {};
      Set<String> digitalIds = {};

      final sub1 = FirebaseFirestore.instance
          .collectionGroup('saves')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        normalIds = snapshot.docs
            .map((doc) => doc.reference.parent.parent?.id ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

        controller.add({...normalIds, ...digitalIds}.length);
      });

      final sub2 = FirebaseFirestore.instance
          .collection('digital_saved_references')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        digitalIds = snapshot.docs
            .map((doc) => (doc.data()['articleId'] ?? doc.id).toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        controller.add({...normalIds, ...digitalIds}.length);
      });

      controller.onCancel = () {
        sub1.cancel();
        sub2.cancel();
      };
    });
  }

  Stream<int> _combinedDownloadsCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return Stream<int>.multi((controller) {
      Set<String> normalIds = {};
      Set<String> digitalIds = {};

      final sub1 = FirebaseFirestore.instance
          .collectionGroup('downloads')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        normalIds = snapshot.docs
            .map((doc) => doc.reference.parent.parent?.id ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

        controller.add({...normalIds, ...digitalIds}.length);
      });

      final sub2 = FirebaseFirestore.instance
          .collection('digital_downloads')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        digitalIds = snapshot.docs
            .map((doc) => (doc.data()['articleId'] ?? doc.id).toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        controller.add({...normalIds, ...digitalIds}.length);
      });

      controller.onCancel = () {
        sub1.cancel();
        sub2.cancel();
      };
    });
  }

  Future<void> _openUpload(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تم رفع الملف بنجاح، ويمكنك متابعته من مكتبتي'),
          ),
        );
    }
  }

  void _openList(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyFilesListScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MyLibraryHeroCard(
              onUploadTap: () => _openUpload(context),
            ),
            const SizedBox(height: 18),
            Text(
              'مؤشرات مكتبتي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'نظرة سريعة على ملفاتك، محفوظاتك، وتنزيلاتك',
              style: TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
                color: LibraryTheme.muted(context),
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<int>(
              stream: _combinedReferencesCount(),
              builder: (context, snapshot) {
                return _PrimaryStatCard(
                  title: 'إجمالي المحفوظات',
                  subtitle: 'المراجع والمصادر الخاصة بك',
                  count: snapshot.data ?? 0,
                  icon: Icons.bookmark_rounded,
                  onTap: () => _openList(context, 'المراجع'),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _combinedDownloadsCount(),
                    builder: (context, snapshot) {
                      return _SecondaryStatCard(
                        title: 'تنزيلاتي',
                        count: snapshot.data ?? 0,
                        icon: Icons.download_rounded,
                        onTap: () => _openList(context, 'تنزيلاتي'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: LibraryFilesService.myUploadedFiles(),
                    builder: (context, snapshot) {
                      return _SecondaryStatCard(
                        title: 'ما رفعته',
                        count: snapshot.data?.docs.length ?? 0,
                        icon: Icons.cloud_upload_rounded,
                        onTap: () => _openList(context, 'ما رفعته'),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<int>(
              stream: _collectionGroupCount('shares'),
              builder: (context, snapshot) {
                return _SecondaryStatCard(
                  title: 'مشاركاتي',
                  count: snapshot.data ?? 0,
                  icon: Icons.share_rounded,
                  isFullWidth: true,
                  onTap: () => _openList(context, 'ما شاركته'),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _MyLibraryHeroCard extends StatelessWidget {
  final VoidCallback onUploadTap;

  const _MyLibraryHeroCard({required this.onUploadTap});

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A227);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LibraryTheme.surface(context),
        gradient: LinearGradient(
          colors: [
            LibraryTheme.surface(context),
            isDark ? LibraryTheme.surface(context) : gold.withOpacity(0.015),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? LibraryTheme.border(context)
              : LibraryTheme.border(context).withOpacity(0.65),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gold.withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  Icons.folder_special_rounded,
                  color: gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مكتبتي الشخصية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LibraryTheme.text(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'إدارة جميع ملفاتك ومصادرك',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: LibraryTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: LibraryTheme.bg(context).withOpacity(isDark ? 0.45 : 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: LibraryTheme.border(context).withOpacity(0.45),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _FeatureChip(icon: Icons.cloud_upload_outlined, label: 'رفع'),
                _FeatureChip(icon: Icons.bookmark_outline_rounded, label: 'حفظ'),
                _FeatureChip(icon: Icons.download_outlined, label: 'تنزيل'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUploadTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'رفع ملف جديد',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: LibraryTheme.muted(context),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.2,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
      ],
    );
  }
}

class _PrimaryStatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryStatCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = const Color(0xFFC9A227);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: LibraryTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gold.withOpacity(isDark ? 0.18 : 0.65),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.20)
                  : gold.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: gold,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: LibraryTheme.text(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: LibraryTheme.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text(context),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryStatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _SecondaryStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LibraryTheme.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? LibraryTheme.border(context)
                : LibraryTheme.border(context).withOpacity(0.55),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isFullWidth ? _buildFullWidth(context) : _buildCompact(context),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LibraryTheme.bg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: LibraryTheme.muted(context),
                size: 18,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text(context),
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidth(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LibraryTheme.bg(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: LibraryTheme.muted(context),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: LibraryTheme.text(context),
            height: 1,
          ),
        ),
      ],
    );
  }
}