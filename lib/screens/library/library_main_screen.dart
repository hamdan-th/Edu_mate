import 'package:flutter/material.dart';

import 'digital_library_screen.dart';
import 'my_library_screen.dart';
import 'university_library_screen.dart';

class LibraryMainScreen extends StatefulWidget {
  const LibraryMainScreen({Key? key}) : super(key: key);

  @override
  State<LibraryMainScreen> createState() => _LibraryMainScreenState();
}

class _LibraryMainScreenState extends State<LibraryMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    UniversityLibraryScreen(),
    DigitalLibraryScreen(),
    MyLibraryScreen(),
  ];

  final List<_LibraryTabItem> _tabs = const [
    _LibraryTabItem(
      title: 'مكتبة الجامعة',
      icon: Icons.school_rounded,
    ),
    _LibraryTabItem(
      title: 'المكتبة الرقمية',
      icon: Icons.language_rounded,
    ),
    _LibraryTabItem(
      title: 'مكتبتي',
      icon: Icons.folder_copy_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_selectedIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _ModernHeader(
                currentTab: currentTab,
                selectedIndex: _selectedIndex,
                tabs: _tabs,
                onTabChanged: (i) => setState(() => _selectedIndex = i),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernHeader extends StatelessWidget {
  final _LibraryTabItem currentTab;
  final int selectedIndex;
  final List<_LibraryTabItem> tabs;
  final ValueChanged<int> onTabChanged;

  const _ModernHeader({
    required this.currentTab,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.primaryColor,
        gradient: isDark ? LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ) : null,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  currentTab.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTab.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'مكتبة ذكية لتنظيم الملفات والمراجع والبحث الأكاديمي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.8,
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final item = tabs[index];
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).cardTheme.color : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 19,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.4,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTabItem {
  final String title;
  final IconData icon;

  const _LibraryTabItem({
    required this.title,
    required this.icon,
  });
}