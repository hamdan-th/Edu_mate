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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              onUploadTap: () => _openUpload(context),
            ),
            const SizedBox(height: 32),
            const _SectionHeader(
              title: 'مؤشرات مكتبتي',
              subtitle: 'إحصائيات سريعة لكل ما يتعلق بملفاتك وتفاعلاتك',
            ),
            const SizedBox(height: 20),
            
            // Primary Status Cards
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _combinedReferencesCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _PrimaryStatCard(
                        title: 'المراجع',
                        subtitle: 'المحفوظات',
                        count: count,
                        icon: Icons.bookmark_rounded,
                        accentColor: const Color(0xFFD4AF37), // Premium Gold
                        onTap: () => _openList(context, 'المراجع'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _combinedDownloadsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _PrimaryStatCard(
                        title: 'تنزيلاتي',
                        subtitle: 'المنزّل',
                        count: count,
                        icon: Icons.download_rounded,
                        accentColor: LibraryTheme.primary(context),
                        onTap: () => _openList(context, 'تنزيلاتي'),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),

            // Secondary Status Cards
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: LibraryFilesService.myUploadedFiles(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return _SecondaryStatCard(
                        title: 'ما رفعته',
                        count: count,
                        icon: Icons.cloud_upload_rounded,
                        onTap: () => _openList(context, 'ما رفعته'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _collectionGroupCount('shares'),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _SecondaryStatCard(
                        title: 'ما شاركته',
                        count: count,
                        icon: Icons.send_rounded,
                        onTap: () => _openList(context, 'ما شاركته'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onUploadTap;

  const _HeroCard({required this.onUploadTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LibraryTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: LibraryTheme.border(context).withOpacity(isDark ? 0.3 : 0.5),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary(context).withOpacity(isDark ? 0.05 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5C158), Color(0xFFD4AF37)], // Gold gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
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
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: LibraryTheme.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مساحتك الخاصة للتعلم والاستكشاف',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: LibraryTheme.muted(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              _TinyChip(icon: Icons.upload_file_rounded, label: 'رفع'),
              SizedBox(width: 8),
              _TinyChip(icon: Icons.bookmark_rounded, label: 'حفظ'),
              SizedBox(width: 8),
              _TinyChip(icon: Icons.download_rounded, label: 'تنزيل'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUploadTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: LibraryTheme.primary(context),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: LibraryTheme.primary(context).withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
              label: const Text(
                'رفع ملف جديد',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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

class _TinyChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LibraryTheme.bg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: LibraryTheme.border(context).withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: LibraryTheme.muted(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: LibraryTheme.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStatCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _PrimaryStatCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PrimaryStatCard> createState() => _PrimaryStatCardState();
}

class _PrimaryStatCardState extends State<_PrimaryStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        child: Container(
          height: 180, // Taller for premium feel
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: LibraryTheme.surface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accentColor.withOpacity(isDark ? 0.15 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(isDark ? 0.05 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  size: 26,
                  color: widget.accentColor,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: LibraryTheme.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: LibraryTheme.text(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LibraryTheme.muted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryStatCard extends StatefulWidget {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SecondaryStatCard> createState() => _SecondaryStatCardState();
}

class _SecondaryStatCardState extends State<_SecondaryStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: LibraryTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: LibraryTheme.border(context).withOpacity(isDark ? 0.3 : 0.5),
              width: 0.8,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LibraryTheme.bg(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: LibraryTheme.muted(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: LibraryTheme.text(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: LibraryTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: LibraryTheme.text(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: LibraryTheme.muted(context),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}