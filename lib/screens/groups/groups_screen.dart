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
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    bool isMember = false;
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(group.id).collection('members').doc(user.uid).get();
      if (doc.exists) isMember = true;
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

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
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                  const Text('تصفية النتائج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),
                  
                  // College Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'الكلية',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppColors.primary.withOpacity(0.04),
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Specialization Dropdown
                  if (currentCollege != null)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'التخصص',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                      value: tempSpecId,
                      items: currentCollege.specializations.map((spec) => DropdownMenuItem(value: spec.id, child: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (val) => setModalState(() => tempSpecId = val),
                    ),
                  if (currentCollege != null) const SizedBox(height: 20),
                  
                  // Switch
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            foregroundColor: Colors.white,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: !_isSearching,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مجتمع...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              )
            : const Text("المجتمعات", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: AppColors.textPrimary),
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
          preferredSize: const Size.fromHeight(54),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              dividerColor: AppColors.border.withOpacity(0.5),
              tabs: const [
                Tab(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("اكتشف"))),
                Tab(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("مجموعاتي"))),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildMyGroupsTab(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0),
        child: FloatingActionButton.extended(
          onPressed: _openCreateGroup,
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: const Text("مجموعة جديدة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: GroupService.streamDiscoverGroups(search: ''),
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildDiscoverCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildMyGroupsTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: GroupService.streamMyGroups(),
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

        return ListView.separated(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount: items.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(left: 16, right: 88), 
            child: Divider(height: 1, thickness: 1, color: AppColors.border.withOpacity(0.6)),
          ),
          itemBuilder: (context, index) {
            return _buildMyGroupTile(items[index]);
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCard(GroupModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleGroupTap(group),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + Title + Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: group.imageUrl.isNotEmpty ? NetworkImage(group.imageUrl) : null,
                      child: group.imageUrl.isEmpty
                          ? Text(
                              group.name.isNotEmpty ? group.name[0].toUpperCase() : 'M',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24),
                            )
                          : null,
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
                                  group.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: group.isPublic ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(group.isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 12, color: group.isPublic ? AppColors.success : AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      group.isPublic ? "عامة" : "خاصة",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: group.isPublic ? AppColors.success : AppColors.warning),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.school_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${group.collegeName} • ${group.specializationName}",
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    group.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                // Join Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _handleGroupTap(group),
                    child: const Text("استعراض المجموعة", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyGroupTile(GroupModel group) {
    return InkWell(
      onTap: () => _openGroupChat(group),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: group.imageUrl.isNotEmpty ? NetworkImage(group.imageUrl) : null,
              child: group.imageUrl.isEmpty
                  ? Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : 'M',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22),
                    )
                  : null,
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
                          group.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.messagesCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${group.messagesCount}", 
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.description.isNotEmpty ? group.description : group.specializationName,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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