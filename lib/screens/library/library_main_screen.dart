import 'package:flutter/material.dart';
import 'digital_library_screen.dart';
import 'library_theme.dart';
import 'my_library_screen.dart';
import 'university_library_screen.dart';

class LibraryMainScreen extends StatefulWidget {
  const LibraryMainScreen({Key? key}) : super(key: key);

  @override
  State<LibraryMainScreen> createState() => _LibraryMainScreenState();
}

class _LibraryMainScreenState extends State<LibraryMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LibraryTheme.primaryGradient;

    return Scaffold(
      backgroundColor: LibraryTheme.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: LibraryTheme.surface,
        elevation: 0,
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => gradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: const Icon(Icons.local_library_rounded, size: 36),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: LibraryTheme.primary,
          unselectedLabelColor: LibraryTheme.muted,
          indicatorColor: LibraryTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'مكتبة الجامعة'),
            Tab(text: 'مكتبة رقمية'),
            Tab(text: 'مكتبتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UniversityLibraryScreen(),
          DigitalLibraryScreen(),
          MyLibraryScreen(),
        ],
      ),
    );
  }
}