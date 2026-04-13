import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/guest_provider.dart';
import '../../features/edu_bot/presentation/widgets/floating_bot_button.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/guest_action_dialog.dart';
import 'digital_library_screen.dart';
import 'library_theme.dart';
import 'my_library_screen.dart';
import 'university_library_screen.dart';

class LibraryMainScreen extends StatefulWidget {
  const LibraryMainScreen({super.key});

  @override
  State<LibraryMainScreen> createState() => _LibraryMainScreenState();
}

class _LibraryMainScreenState extends State<LibraryMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const UniversityLibraryScreen(),
    const DigitalLibraryScreen(),
    const MyLibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<_LibraryTabItem> tabs = [
      _LibraryTabItem(
        title: l10n.libraryTabUniversity,
        icon: Icons.school_rounded,
      ),
      _LibraryTabItem(
        title: l10n.libraryTabDigital,
        icon: Icons.language_rounded,
      ),
      _LibraryTabItem(
        title: l10n.libraryTabMyLibrary,
        icon: Icons.folder_copy_rounded,
      ),
    ];

    final currentTab = tabs[_selectedIndex];

    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      floatingActionButton: const SafeArea(
        child: FloatingBotButton(
          sourceScreen: 'library_screen',
          padding: EdgeInsets.only(bottom: 16),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _ModernHeader(
                currentTab: currentTab,
                selectedIndex: _selectedIndex,
                tabs: tabs,
                onTabChanged: (i) {
                  // 🚫 Guest cannot access My Library (index 2)
                  if (i == 2 && context.read<GuestProvider>().isGuest) {
                    GuestActionDialog.show(context);
                    return;
                  }
                  setState(() => _selectedIndex = i);
                },
              ),
            ),

            const SizedBox(height: 12),

            /// 🔥 Animated page switch
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LibraryTheme.primary(context),
            LibraryTheme.secondary(context),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: LibraryTheme.primary(context).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          /// 🔥 HEADER
          Row(
            children: [
              /// 🔥 Glass Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
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
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.libraryHeaderSubtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// 🔥 MODERN TABS
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: List.generate(
                tabs.length,
                    (index) {
                  final tab = tabs[index];
                  final active = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: active
                              ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                            )
                          ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: active ? 1.05 : 1,
                              child: Icon(
                                tab.icon,
                                color: active
                                    ? LibraryTheme.primary(context)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                tab.title,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? LibraryTheme.primary(context)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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