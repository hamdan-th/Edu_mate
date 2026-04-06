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

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  bool _isSearching = false;

  late final Stream<List<GroupModel>> _discoverStream;
  late final Stream<List<GroupModel>> _myGroupsStream;

  // Filters State
  String? _selectedCollegeId;
  String? _selectedSpecializationId;
  bool _publicOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1); // Default to My Groups
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
                top: 16, left: 24, right: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48, height: 5, 
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))
                    )
                  ),
                  const SizedBox(height: 24),
                  const Text('تصفية النتائج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  
                  // College Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'الكلية',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    value: tempCollegeId,
                    items: AcademicStructure.colleges.map((col) => DropdownMenuItem(value: col.id, child: Text(col.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        tempCollegeId = val;
                        tempSpecId = null;
                      });
                    },
                    dropdownColor: Theme.of(context).cardTheme.color,
                  ),
                  const SizedBox(height: 16),
                  
                  // Specialization Dropdown
                  if (currentCollege != null)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'التخصص',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                      value: tempSpecId,
                      items: currentCollege.specializations.map((spec) => DropdownMenuItem(value: spec.id, child: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (val) => setModalState(() => tempSpecId = val),
                      dropdownColor: Theme.of(context).cardTheme.color,
                    ),
                  if (currentCollege != null) const SizedBox(height: 20),
                  
                  // Switch
                  Container(
                    child: SwitchListTile(
                      title: const Text('المجموعات العامة فقط', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      value: tempPublicOnly,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onChanged: (val) => setModalState(() => tempPublicOnly = val),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCollegeId = null;
                              _selectedSpecializationId = null;
                              _publicOnly = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('إلغاء التصفية', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 16)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          child: const Text('تطبيق', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
      if (_selectedCollegeId != null && g.collegeId != _selectedCollegeId) return false;
      if (_selectedSpecializationId != null && g.specializationId != _selectedSpecializationId) return false;
      if (_search.isNotEmpty) {
        final match = g.name.toLowerCase().contains(_search) || g.description.toLowerCase().contains(_search);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: !_isSearching,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مجتمع...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                ),
              )
            : Text(
                "المجتمعات", 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: AppColors.primary),
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
          preferredSize: const Size.fromHeight(58), // slightly more space for smooth track
          child: Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
              dividerColor: AppColors.border.withOpacity(0.1),
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
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
        padding: const EdgeInsets.only(bottom: 110.0), // Floating above bottom nav perfectly
        child: FloatingActionButton(
          onPressed: _openCreateGroup,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: 10,
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

        final items = _applyFiltersAndSearch(snapshot.data!);

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.travel_explore_rounded,
            title: "لا توجد مجتمعات متاحة للاكتشاف",
            subtitle: "لم نتمكن من العثور على أي مجتمعات عامة تطابق معاييرك حالياً. يمكنك إنشاء مجتمعك الخاص!",
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

        final items = _applyFiltersAndSearch(snapshot.data!);

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: "لست عضواً في أي مجتمع",
            subtitle: "انضم إلى المجموعات الأكاديمية للتواصل مع زملائك، أو قم بإنشاء مجموعة جديدة.",
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

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), height: 1.6, fontWeight: FontWeight.w500),
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

  const _PremiumGroupCard({required this.group, required this.isDiscover});

  @override
  State<_PremiumGroupCard> createState() => _PremiumGroupCardState();
}

class _PremiumGroupCardState extends State<_PremiumGroupCard> {
  bool _isPressed = false;

  void _openGroupDetails() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: widget.group)));
  }

  void _openGroupChat() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(group: widget.group)));
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
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    bool isMember = false;
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.group.id).collection('members').doc(user.uid).get();
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
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8), // Soft float effect
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
                    // Premium Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2), // gentle inner glow spread
                            blurRadius: 10,
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
                                  colors: [AppColors.primary, Color(0xFFC79A22)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            if (widget.group.imageUrl.isNotEmpty)
                              Image.network(widget.group.imageUrl, fit: BoxFit.cover, width: 52, height: 52)
                            else
                              Text(
                                widget.group.name.isNotEmpty ? widget.group.name[0].toUpperCase() : 'G',
                                style: const TextStyle(
                                  color: AppColors.secondary, 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 22,
                                  letterSpacing: 0,
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.group.name,
                                  style: TextStyle(
                                    fontSize: 17, 
                                    fontWeight: FontWeight.w900, 
                                    color: Theme.of(context).textTheme.bodyLarge?.color, 
                                    letterSpacing: 0.3
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Badges (Count or Public/Private indicator)
                              if (!widget.isDiscover && widget.group.messagesCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 0.5),
                                  ),
                                  child: Text(
                                    widget.group.messagesCount > 99 ? "+99" : "${widget.group.messagesCount}", 
                                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800)
                                  ),
                                ),
                                
                              if (widget.isDiscover)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.group.isPublic ? AppColors.success.withOpacity(0.10) : AppColors.warning.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.group.isPublic ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(widget.group.isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 10, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.group.isPublic ? "عامة" : "خاصة",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Metadata sub-line
                          if (widget.isDiscover)
                            Row(
                              children: [
                                Icon(Icons.school_rounded, size: 14, color: AppColors.primary.withOpacity(0.8)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${widget.group.collegeName} • ${widget.group.specializationName}",
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              widget.group.description.isNotEmpty ? widget.group.description : widget.group.specializationName,
                              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontWeight: FontWeight.w500, height: 1.4),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (widget.isDiscover && widget.group.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.group.description,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), height: 1.5, fontWeight: FontWeight.w500),
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

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}