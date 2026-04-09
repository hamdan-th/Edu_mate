import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../data/academic_structure.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';
import 'group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  bool _isSearching = false;

  late final Stream<List<GroupModel>> _discoverStream;
  late final Stream<List<GroupModel>> _myGroupsStream;

  String? _selectedCollegeId;
  String? _selectedSpecializationId;
  bool _publicOnly = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? const Color(0xFF0B0D12) : const Color(0xFFF4F5F7);
  Color get _surface =>
      _isDark ? const Color(0xFF141922) : Colors.white;
  Color get _surfaceSoft =>
      _isDark ? const Color(0xFF10141C) : const Color(0xFFF8F9FB);
  Color get _text =>
      _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted =>
      _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border =>
      _isDark ? Colors.white.withOpacity(0.07) : Colors.black12;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _discoverStream = GroupService.streamDiscoverGroups(search: '');
    _myGroupsStream = GroupService.streamMyGroups();

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateGroup() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (created == true && mounted) {
      _tabController.animateTo(1);
    }
  }

  void _openFilterModal() {
    String? tempCollegeId = _selectedCollegeId;
    String? tempSpecId = _selectedSpecializationId;
    bool tempPublicOnly = _publicOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            CollegeItem? currentCollege;
            if (tempCollegeId != null) {
              currentCollege = AcademicStructure.colleges.firstWhere(
                    (c) => c.id == tempCollegeId,
                orElse: () => AcademicStructure.colleges.first,
              );
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg =
            isDark ? const Color(0xFF161B24) : Colors.white;
            final fieldBg =
            isDark ? const Color(0xFF0F141C) : const Color(0xFFF8F9FB);
            final border =
            isDark ? Colors.white.withOpacity(0.08) : Colors.black12;
            final textColor =
            isDark ? AppColors.textPrimary : Colors.black87;
            final muted =
            isDark ? AppColors.textSecondary : Colors.black54;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تصفية النتائج',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'الكلية',
                      labelStyle: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    dropdownColor: sheetBg,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                    initialValue: tempCollegeId,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                    items: AcademicStructure.colleges
                        .map(
                          (col) => DropdownMenuItem(
                        value: col.id,
                        child: Text(
                          col.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        tempCollegeId = val;
                        tempSpecId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (currentCollege != null)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'التخصص',
                        labelStyle: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      dropdownColor: sheetBg,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                      initialValue: tempSpecId,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      items: currentCollege.specializations
                          .map(
                            (spec) => DropdownMenuItem(
                          value: spec.id,
                          child: Text(
                            spec.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => tempSpecId = val),
                    ),
                  if (currentCollege != null) const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'المجموعات العامة فقط',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      value: tempPublicOnly,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) =>
                          setModalState(() => tempPublicOnly = val),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCollegeId = null;
                              _selectedSpecializationId = null;
                              _publicOnly = false;
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'إلغاء التصفية',
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCollegeId = tempCollegeId;
                              _selectedSpecializationId = tempSpecId;
                              _publicOnly = tempPublicOnly;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'تطبيق',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<GroupModel> _applyFiltersAndSearch(List<GroupModel> groups) {
    return groups.where((g) {
      if (_publicOnly && !g.isPublic) return false;
      if (_selectedCollegeId != null && g.collegeId != _selectedCollegeId) {
        return false;
      }
      if (_selectedSpecializationId != null &&
          g.specializationId != _selectedSpecializationId) {
        return false;
      }
      if (_search.isNotEmpty) {
        final match = g.name.toLowerCase().contains(_search) ||
            g.description.toLowerCase().contains(_search);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: !_isSearching,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن مجتمع...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: _muted.withOpacity(0.65)),
          ),
        )
            : Text(
          "المجتمعات",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.5,
            color: _text,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: _openFilterModal,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            color: _surfaceSoft,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: _muted.withOpacity(0.85),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3.2,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              dividerColor: _border.withOpacity(0.5),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: "اكتشف"),
                Tab(text: "مجموعاتي"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _KeepAlivePage(child: _buildDiscoverTab()),
          _KeepAlivePage(child: _buildMyGroupsTab()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton(
          onPressed: _openCreateGroup,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: _isDark ? 2 : 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: _discoverStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = _applyFiltersAndSearch(snapshot.data!);

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.travel_explore_rounded,
            title: "لا توجد مجتمعات متاحة للاكتشاف",
            subtitle:
            "لم نتمكن من العثور على أي مجتمعات عامة تطابق معاييرك حالياً. يمكنك إنشاء مجتمعك الخاص!",
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _PremiumGroupCard(group: items[index], isDiscover: true);
          },
        );
      },
    );
  }

  Widget _buildMyGroupsTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: _myGroupsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = _applyFiltersAndSearch(snapshot.data!);

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: "لست عضواً في أي مجتمع",
            subtitle:
            "انضم إلى المجموعات الأكاديمية للتواصل مع زملائك، أو قم بإنشاء مجموعة جديدة.",
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _PremiumGroupCard(group: items[index], isDiscover: false);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(_isDark ? 0.12 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: _muted.withOpacity(0.85),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumGroupCard extends StatefulWidget {
  final GroupModel group;
  final bool isDiscover;

  const _PremiumGroupCard({
    required this.group,
    required this.isDiscover,
  });

  @override
  State<_PremiumGroupCard> createState() => _PremiumGroupCardState();
}

class _PremiumGroupCardState extends State<_PremiumGroupCard> {
  bool _isPressed = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? const Color(0xFF151B24) : Colors.white;
  Color get _text =>
      _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted =>
      _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border =>
      _isDark ? Colors.white.withOpacity(0.07) : Colors.black12;

  void _openGroupDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(group: widget.group),
      ),
    );
  }

  void _openGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(group: widget.group),
      ),
    );
  }

  Future<void> _handleTap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _openGroupDetails();
      return;
    }
    if (widget.group.ownerId == user.uid) {
      _openGroupChat();
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    bool isMember = false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .doc(user.uid)
          .get();
      if (doc.exists) isMember = true;
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (isMember) {
      _openGroupChat();
    } else {
      _openGroupDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.16 : 0.04),
                blurRadius: _isDark ? 14 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isDiscover ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(_isDark ? 0.16 : 0.22),
                            blurRadius: _isDark ? 12 : 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFFC79A22),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            if (widget.group.imageUrl.isNotEmpty)
                              Image.network(
                                widget.group.imageUrl,
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                              )
                            else
                              Text(
                                widget.group.name.isNotEmpty
                                    ? widget.group.name[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.group.name,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _text,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!widget.isDiscover &&
                                  widget.group.messagesCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color:
                                      AppColors.primary.withOpacity(0.24),
                                    ),
                                  ),
                                  child: Text(
                                    widget.group.messagesCount > 99
                                        ? "+99"
                                        : "${widget.group.messagesCount}",
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              if (widget.isDiscover)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.group.isPublic
                                        ? AppColors.success.withOpacity(0.10)
                                        : AppColors.warning.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: widget.group.isPublic
                                          ? AppColors.success
                                          .withOpacity(0.22)
                                          : AppColors.warning
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.group.isPublic
                                            ? Icons.public_rounded
                                            : Icons.lock_rounded,
                                        size: 11,
                                        color: widget.group.isPublic
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.group.isPublic
                                            ? "عامة"
                                            : "خاصة",
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: widget.group.isPublic
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (widget.isDiscover)
                            Row(
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: AppColors.primary.withOpacity(0.85),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${widget.group.collegeName} • ${widget.group.specializationName}",
                                    style: TextStyle(
                                      fontSize: 12.8,
                                      color: _muted.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              widget.group.description.isNotEmpty
                                  ? widget.group.description
                                  : widget.group.specializationName,
                              style: TextStyle(
                                fontSize: 14.2,
                                color: _muted.withOpacity(0.88),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.isDiscover &&
                    widget.group.description.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    widget.group.description,
                    style: TextStyle(
                      fontSize: 14.2,
                      color: _muted.withOpacity(0.9),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}