import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'my_files_list_screen.dart';
import 'upload_screen.dart';

class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UploadSummaryCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.2,
              children: [
                CategoryCard(
                  title: 'ما رفعته',
                  itemCount: 15,
                  icon: Icons.cloud_upload_rounded,
                  gradient: const [LibraryTheme.primary, LibraryTheme.secondary],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MyFilesListScreen(title: 'ما رفعته'),
                    ),
                  ),
                ),
                CategoryCard(
                  title: 'ما شاركته',
                  itemCount: 8,
                  icon: Icons.share_rounded,
                  gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MyFilesListScreen(title: 'ما شاركته'),
                    ),
                  ),
                ),
                CategoryCard(
                  title: 'المراجع',
                  itemCount: 23,
                  icon: Icons.bookmark_rounded,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MyFilesListScreen(title: 'المراجع'),
                    ),
                  ),
                ),
                CategoryCard(
                  title: 'تنزيلاتي',
                  itemCount: 5,
                  icon: Icons.cloud_download_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF14B8A6)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MyFilesListScreen(title: 'تنزيلاتي'),
                    ),
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

class _UploadSummaryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadSummaryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LibraryTheme.primary, LibraryTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: LibraryTheme.primary.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.note_add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إضافة ملخص',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ارفع PDF أو صورة أو ملف جديد إلى مكتبتك',
                    style: TextStyle(
                      color: Color(0xFFE9E7FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final int itemCount;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.itemCount,
    required this.icon,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.30),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 4),
              Icon(icon, size: 40, color: Colors.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount ملف',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
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