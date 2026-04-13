import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';
import '../../data/academic_structure.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';
import 'group_chat_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../features/edu_bot/presentation/widgets/floating_bot_button.dart';

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
  Color get _pageBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardBg => _isDark ? AppColors.surface : Colors.white;
  Color get _softBg =>
      _isDark ? AppColors.background.withOpacity(0.6) : const Color(0xFFF7F8FB);
  Color get _text =>
      _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted =>
      _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border =>
      _isDark ? AppColors.border : Colors.black12;

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
    // 🚫 Guest cannot create groups
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
      return;
    }
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

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 14,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          color: AppColors.primary.withOpacity(0.95), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.groupsFilterTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: tempCollegeId,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.filterCollege,
                      labelStyle: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: _softBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: _border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                    items: AcademicStructure.colleges
                        .map(
                          (col) => DropdownMenuItem(
                        value: col.id,
                        child: Text(
                          col.name,
                          style:
                          TextStyle(color: _text, fontWeight: FontWeight.w700),
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
                    dropdownColor: _cardBg,
                  ),
                  const SizedBox(height: 14),
                  if (currentCollege != null)
                    DropdownButtonFormField<String>(
                      initialValue: tempSpecId,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.filterMajor,
                        labelStyle: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: _softBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: _border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                      items: currentCollege.specializations
                          .map(
                            (spec) => DropdownMenuItem(
                          value: spec.id,
                          child: Text(
                            spec.name,
                            style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setModalState(() => tempSpecId = val),
                      dropdownColor: _cardBg,
                    ),
                  if (currentCollege != null) const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: _softBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.groupsFilterPublicOnly,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: _text,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.groupsFilterPublicOnlySub,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: tempPublicOnly,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) =>
                          setModalState(() => tempPublicOnly = val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                            AppLocalizations.of(context)!.groupsFilterReset,
                            style: TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                          child: Text(
                            AppLocalizations.of(context)!.groupsFilterApply,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
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
            g.description.toLowerCase().contains(_search) ||
            g.specializationName.toLowerCase().contains(_search) ||
            g.collegeName.toLowerCase().contains(_search);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        centerTitle: !_isSearching,
        toolbarHeight: 66,
        title: _isSearching
            ? Container(
          height: 46,
          decoration: BoxDecoration(
            color: _softBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.groupsSearchFieldHint,
              hintStyle: TextStyle(
                color: _isDark ? _muted.withOpacity(0.7) : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _muted,
              ),
            ),
          ),
        )
            : Text(
          AppLocalizations.of(context)!.groupsAppBarTitle,
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Row(
              children: [
                _TopActionButton(
                  icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  onTap: () {
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
                const SizedBox(width: 8),
                _TopActionButton(
                  icon: Icons.tune_rounded,
                  onTap: _openFilterModal,
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Container(
            color: _cardBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _softBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _isDark
                      ? AppColors.primary.withOpacity(0.16)
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: _isDark ? _muted : const Color(0xFF4B5563),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.groupsTabDiscover),
                  Tab(text: AppLocalizations.of(context)!.groupsTabMyGroups),
                ],
              ),
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
        padding: const EdgeInsets.only(bottom: 92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const FloatingBotButton(
              sourceScreen: 'groups_screen',
              padding: EdgeInsets.only(bottom: 16),
            ),
            FloatingActionButton(
              onPressed: _openCreateGroup,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ],
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
            title: AppLocalizations.of(context)!.groupsEmptyDiscoverTitle,
            subtitle: AppLocalizations.of(context)!.groupsEmptyDiscoverSub,
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _PremiumGroupCard(
              group: items[index],
              isDiscover: true,
            );
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
            icon: Icons.groups_rounded,
            title: AppLocalizations.of(context)!.groupsEmptyMyGroupsTitle,
            subtitle: AppLocalizations.of(context)!.groupsEmptyMyGroupsSub,
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _PremiumGroupCard(
              group: items[index],
              isDiscover: false,
            );
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
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _isDark
                    ? Colors.black.withOpacity(0.22)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(_isDark ? 0.10 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: _muted,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface.withOpacity(0.98) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.border
                : Colors.black12,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF374151),
          size: 20,
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
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;

  @override
  void initState() {
    super.initState();
    if (!widget.isDiscover) {
      _unreadSub = GroupService.streamUnreadCount(widget.group.id)
          .listen((count) {
        if (mounted) setState(() => _unreadCount = count);
      });
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppColors.surface : Colors.white;
  Color get _softBg =>
      _isDark ? AppColors.background.withOpacity(0.6) : const Color(0xFFF8FAFD);
  Color get _text =>
      _isDark ? AppColors.textPrimary : Colors.black87;
  Color get _muted =>
      _isDark ? AppColors.textSecondary : Colors.black54;
  Color get _border =>
      _isDark ? AppColors.border : Colors.black12;

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

    // 🚫 Guest cannot enter group chat
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(context);
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
    final group = widget.group;
    final displaySubtitle = widget.isDiscover
        ? '${group.collegeName} • ${group.specializationName}'
        : (group.specializationName.isNotEmpty
        ? group.specializationName
        : group.collegeName);

    final description = group.description.trim();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _isDark
                    ? Colors.black.withOpacity(0.20)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupAvatar(group: group),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: _text,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.isDiscover)
                            _TinyPill(
                              icon: group.isPublic
                                  ? Icons.public_rounded
                                  : Icons.lock_rounded,
                              text: group.isPublic ? AppLocalizations.of(context)!.groupsPillPublic : AppLocalizations.of(context)!.groupsPillPrivate,
                              bg: group.isPublic
                                  ? AppColors.success.withOpacity(_isDark ? 0.10 : 0.18)
                                  : AppColors.warning.withOpacity(_isDark ? 0.10 : 0.18),
                              fg: group.isPublic
                                  ? (_isDark ? AppColors.success : const Color(0xFF059669))
                                  : (_isDark ? AppColors.warning : const Color(0xFFD97706)),
                            )
                          else if (_unreadCount > 0)
                            _UnreadBadge(count: _unreadCount),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: AppColors.primary.withOpacity(0.85),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              displaySubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.8,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (widget.isDiscover)
                        // Discover: show group description as before
                        if (description.isNotEmpty)
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.4,
                              color: _muted.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _softBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.groupsCardDiscoverSub,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                      else
                        // My Groups: show last-message preview
                        _LastMessagePreview(group: group, muted: _muted, softBg: _softBg),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a compact last-message preview row on My Groups cards.
class _LastMessagePreview extends StatelessWidget {
  final GroupModel group;
  final Color muted;
  final Color softBg;

  const _LastMessagePreview({
    required this.group,
    required this.muted,
    required this.softBg,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final text = group.lastMessageText.trim();
    final type = group.lastMessageType;
    final senderId = group.lastMessageSenderId;
    final isMe = senderId.isNotEmpty && senderId == currentUid;

    String preview;
    IconData icon;

    if (text.isEmpty && type.isEmpty) {
      // No messages yet
      preview = AppLocalizations.of(context)!.groupsCardMyGroupsSub;
      icon = Icons.chat_bubble_outline_rounded;
    } else {
      switch (type) {
        case 'image':
          preview = '📷 Photo';
          icon = Icons.image_rounded;
          break;
        case 'library_file_link':
          preview = text.isNotEmpty ? text : '📎 File';
          icon = Icons.attach_file_rounded;
          break;
        default:
          // Plain text or legacy entries without type
          preview = text.isNotEmpty ? text : '...';
          icon = Icons.chat_bubble_rounded;
      }
      if (isMe) preview = 'You: $preview';
    }

    return Row(
      children: [
        Icon(icon, size: 13, color: muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: muted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupAvatar extends StatelessWidget {

  final GroupModel group;

  const _GroupAvatar({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (group.imageUrl.isNotEmpty)
              Image.network(
                group.imageUrl,
                fit: BoxFit.cover,
                width: 58,
                height: 58,
                errorBuilder: (_, __, ___) => _AvatarFallback(name: group.name),
              )
            else
              _AvatarFallback(name: group.name),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'G',
      style: const TextStyle(
        color: AppColors.secondary,
        fontWeight: FontWeight.w900,
        fontSize: 24,
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  const _TinyPill({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact unread-message badge — red pill with count.
class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withOpacity(0.18)
            : AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_chat_unread_rounded,
            size: 11,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: AppColors.error,
            ),
          ),
        ],
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