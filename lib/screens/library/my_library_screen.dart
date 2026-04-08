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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DASHBOARD HERO CARD
            _MyLibraryHeroCard(
              onUploadTap: () => _openUpload(context),
            ),
            
            const SizedBox(height: 32),
            
            // 2. STATS SECTION HEADER
            Text(
              'مؤشرات مكتبتي',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text(context),
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 3. LARGE PRIMARY STAT CARD
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
            
            const SizedBox(height: 14),
            
            // 4. SECONDARY STAT CARDS (Grid Array)
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
                const SizedBox(width: 14),
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
            
            const SizedBox(height: 14),
            
            // 5. FULL WIDTH SECONDARY STAT CARD
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
            
            const SizedBox(height: 32),
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
    final gold = const Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LibraryTheme.surface(context),
        gradient: LinearGradient(
          colors: [
            LibraryTheme.surface(context),
            gold.withOpacity(isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: LibraryTheme.border(context).withOpacity(isDark ? 0.4 : 0.8),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.02 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: gold.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.folder_special_rounded, 
                  color: gold, 
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مكتبتي الشخصية',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: LibraryTheme.text(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إدارة جميع ملفاتك ومصادرك',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LibraryTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: LibraryTheme.bg(context).withOpacity(isDark ? 0.5 : 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LibraryTheme.border(context).withOpacity(0.5),
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
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUploadTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: LibraryTheme.primary(context),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'رفع ملف جديد',
                style: TextStyle(
                  fontSize: 15,
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

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon, 
          size: 16, 
          color: LibraryTheme.muted(context),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
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
    final gold = const Color(0xFFD4AF37);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: LibraryTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gold.withOpacity(isDark ? 0.3 : 0.7),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(isDark ? 0.05 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon, 
                color: gold, 
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: LibraryTheme.text(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LibraryTheme.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text(context),
                height: 1.0,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: LibraryTheme.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: LibraryTheme.border(context).withOpacity(isDark ? 0.3 : 0.6),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.02 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                size: 20,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: LibraryTheme.text(context),
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidth(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: LibraryTheme.text(context),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}