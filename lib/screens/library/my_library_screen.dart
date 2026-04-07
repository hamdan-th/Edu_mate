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
            _HeroCard(
              onUploadTap: () => _openUpload(context),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'مؤشرات مكتبتي',
              subtitle: 'إحصائيات سريعة لكل ما يتعلق بملفاتك وتفاعلاتك',
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.88,
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: LibraryFilesService.myUploadedFiles(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return _StatCard(
                      title: 'ما رفعته',
                      subtitle: 'ملفاتي المضافة',
                      count: count,
                      icon: Icons.cloud_upload_rounded,
                      colors: const [
                        Color(0xFF5B8CFF),
                        Color(0xFF7B61FF),
                      ],
                      onTap: () => _openList(context, 'ما رفعته'),
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: _collectionGroupCount('shares'),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _StatCard(
                      title: 'ما شاركته',
                      subtitle: 'مشاركاتي',
                      count: count,
                      icon: Icons.send_rounded,
                      colors: const [
                        Color(0xFF12B3A8),
                        Color(0xFF1FC8B3),
                      ],
                      onTap: () => _openList(context, 'ما شاركته'),
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: _combinedReferencesCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _StatCard(
                      title: 'المراجع',
                      subtitle: 'المحفوظات',
                      count: count,
                      icon: Icons.bookmark_rounded,
                      colors: const [
                        Color(0xFFF59E0B),
                        Color(0xFFF7B84B),
                      ],
                      onTap: () => _openList(context, 'المراجع'),
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: _combinedDownloadsCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _StatCard(
                      title: 'تنزيلاتي',
                      subtitle: 'المنزّل',
                      count: count,
                      icon: Icons.download_rounded,
                      colors: const [
                        Color(0xFF10B981),
                        Color(0xFF34D399),
                      ],
                      onTap: () => _openList(context, 'تنزيلاتي'),
                    );
                  },
                ),
              ],
            ),
            // SizedBox(height: 22),
            // const _SectionHeader(
            //  title: 'نظرة سريعة',
            //  subtitle: 'معلومات مهمة عن حالة الملفات داخل مكتبتك',
            // ),
            // SizedBox(height: 12),
            // const _InfoCard(
            //  items: [
            // _InfoItemData(
            // icon: Icons.pending_actions_rounded,
            // title: 'الملفات الجديدة تدخل للمراجعة',
            // subtitle:
            // 'أي ملف ترفعه يظهر لك في مكتبتي مباشرة، لكن نشره العام يكون بعد الاعتماد.',
            // ),
            //_InfoItemData(
            // icon: Icons.edit_note_rounded,
            // title: 'التعديل يعيد الملف للمراجعة',
            // subtitle:
            // 'عند تعديل بيانات الملف، يعود لقيد المراجعة للحفاظ على جودة المكتبة.',
            // ),
          ],
        ),
        //  ],
        // ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onUploadTap;

  const _HeroCard({required this.onUploadTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LibraryTheme.surface(context),
            Colors.white,
            LibraryTheme.primary(context).withOpacity(0.06),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5B8CFF),
                      Color(0xFF7B61FF),
                    ],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B61FF).withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
               Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مكتبتي الشخصية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: LibraryTheme.text(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'مساحة مرتبة لملفاتك، محفوظاتك، وتنزيلاتك داخل التطبيق.',
                      style: TextStyle(
                        fontSize: 13.2,
                        color: LibraryTheme.muted(context),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LibraryTheme.bg(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
            ),
            child: const Row(
              children: [
                _MiniFeature(
                  icon: Icons.upload_file_rounded,
                  label: 'رفع',
                ),
                SizedBox(width: 10),
                _MiniFeature(
                  icon: Icons.bookmark_rounded,
                  label: 'حفظ',
                ),
                SizedBox(width: 10),
                _MiniFeature(
                  icon: Icons.download_rounded,
                  label: 'تنزيل',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUploadTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: LibraryTheme.primary(context),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'رفع ملف جديد',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniFeature({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: LibraryTheme.primary(context)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: LibraryTheme.text(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.colors.last.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.28),
                        Colors.white.withOpacity(0.08),
                      ],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 12.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'عنصر',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: LibraryTheme.text(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: LibraryTheme.muted(context),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItemData> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LibraryTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LibraryTheme.border(context).withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 14),
            child: _InfoTile(item: item),
          );
        }),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final _InfoItemData item;

  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: LibraryTheme.primary(context).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            item.icon,
            color: LibraryTheme.primary(context),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: LibraryTheme.text(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: LibraryTheme.muted(context),
                  fontSize: 12.8,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItemData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}