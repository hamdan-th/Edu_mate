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

  // Filters State
  String? _selectedCollegeId;
  String? _selectedSpecializationId;
  bool _publicOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1); // Default to My Groups
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

  void _openGroupDetails(GroupModel group) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)));
  }

  void _openGroupChat(GroupModel group) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)));
  }

  Future<void> _handleGroupTap(GroupModel group) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _openGroupDetails(group);
      return;
    }
    if (group.ownerId == user.uid) {
      _openGroupChat(group);
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    bool isMember = false;
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(group.id).collection('members').doc(user.uid).get();
      if (doc.exists) isMember = true;
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context);

    if (isMember) {
      _openGroupChat(group);
    } else {
      _openGroupDetails(group);
    }
  }

  void _openFilterModal() {
    String? tempCollegeId = _selectedCollegeId;
    String? tempSpecId = _selectedSpecializationId;
    bool tempPublicOnly = _publicOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 16, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('فلترة المجموعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'الكلية',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    value: tempCollegeId,
                    items: AcademicStructure.colleges.map((col) => DropdownMenuItem(value: col.id, child: Text(col.name))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        tempCollegeId = val;
                        tempSpecId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (currentCollege != null)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'التخصص',
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      value: tempSpecId,
                      items: currentCollege.specializations.map((spec) => DropdownMenuItem(value: spec.id, child: Text(spec.name))).toList(),
                      onChanged: (val) => setModalState(() => tempSpecId = val),
                    ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('المجموعات العامة فقط', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: tempPublicOnly,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => tempPublicOnly = val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCollegeId = null;
                              _selectedSpecializationId = null;
                              _publicOnly = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('إعادة تعيين', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          child: const Text('تطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: AppColors.surface, // Clean pure surface background
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text("المجموعات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: AppColors.textPrimary),
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
            icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            onPressed: _openFilterModal,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent, // Disable standard material divider
                tabs: const [
                  Tab(text: "اكتشف"),
                  Tab(text: "مجموعاتي"),
                ],
              ),
              Divider(height: 1, thickness: 1, color: AppColors.border.withOpacity(0.3)), // Sleeker bottom border
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsList(GroupService.streamDiscoverGroups(search: ''), isMyGroups: false),
          _buildGroupsList(GroupService.streamMyGroups(), isMyGroups: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateGroup,
        backgroundColor: AppColors.primary,
        elevation: 2, // Minimal shadow for sleekness
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildGroupsList(Stream<List<GroupModel>> stream, {required bool isMyGroups}) {
    return StreamBuilder<List<GroupModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

        final items = _applyFiltersAndSearch(snapshot.data!);

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMyGroups ? Icons.chat_bubble_outline_rounded : Icons.explore_outlined,
                  size: 64,
                  color: AppColors.border,
                ),
                const SizedBox(height: 16),
                Text(
                  isMyGroups ? "لا توجد مجموعات منضمة" : "لم يتم العثور على مجموعات",
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                )
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: items.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(left: 16, right: 80), // Telegram-style deep indent
            child: Divider(height: 1, thickness: 1, color: AppColors.border.withOpacity(0.3)),
          ),
          itemBuilder: (context, index) {
            return _buildGroupTile(items[index], isMyGroups);
          },
        );
      },
    );
  }

  Widget _buildGroupTile(GroupModel group, bool isMyGroups) {
    return InkWell(
      onTap: () => isMyGroups ? _openGroupChat(group) : _handleGroupTap(group),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: group.imageUrl.isNotEmpty ? NetworkImage(group.imageUrl) : null,
              child: group.imageUrl.isEmpty
                  ? Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : 'M',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isMyGroups) ...[
                        const SizedBox(width: 8),
                        Icon(group.isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMyGroups ? (group.description.isNotEmpty ? group.description : group.specializationName) : group.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}