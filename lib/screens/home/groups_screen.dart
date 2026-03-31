import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/group_service.dart';
import '../../core/theme/app_colors.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: color,
        ),
      );
  }

  bool _matchesQuery(GroupModel group) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    return group.name.toLowerCase().contains(q) ||
        group.description.toLowerCase().contains(q) ||
        group.specializationName.toLowerCase().contains(q) ||
        group.type.toLowerCase().contains(q);
  }

  Stream<List<GroupModel>> _groupsStream() {
    return FirebaseFirestore.instance.collection('groups').snapshots().map(
          (snapshot) {
        final groups = snapshot.docs
            .map(GroupModel.fromDoc)
            .where((g) => g.status != 'deleted')
            .where(_matchesQuery)
            .toList();

        groups.sort((a, b) {
          final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        return groups;
      },
    );
  }

  Stream<Set<String>> _membershipGroupIdsStream() {
    if (_uid.isEmpty) return Stream.value(<String>{});

    return FirebaseFirestore.instance
        .collectionGroup('members')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      final ids = <String>{};
      for (final doc in snapshot.docs) {
        final groupRef = doc.reference.parent.parent;
        if (groupRef != null) ids.add(groupRef.id);
      }
      return ids;
    });
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );

    if (created == true && mounted) {
      _showMessage('تم إنشاء المجموعة بنجاح', color: AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroup,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إنشاء مجموعة'),
      ),
      body: SafeArea(
        child: StreamBuilder<Set<String>>(
          stream: _membershipGroupIdsStream(),
          builder: (context, membershipSnapshot) {
            final memberIds = membershipSnapshot.data ?? <String>{};

            return StreamBuilder<List<GroupModel>>(
              stream: _groupsStream(),
              builder: (context, groupsSnapshot) {
                if (groupsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (groupsSnapshot.hasError) {
                  return const Center(
                    child: Text('حدث خطأ أثناء تحميل المجموعات'),
                  );
                }

                final groups = groupsSnapshot.data ?? [];
                final myGroups = groups
                    .where((g) => memberIds.contains(g.docId) || g.ownerId == _uid)
                    .toList();
                final discoverGroups = groups
                    .where((g) => !memberIds.contains(g.docId) && g.ownerId != _uid)
                    .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _CompactGroupsHeader(
                        searchController: _searchController,
                        tabController: _tabController,
                        myGroupsCount: myGroups.length,
                        discoverCount: discoverGroups.length,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _MyGroupsTab(
                            groups: myGroups,
                            onMessage: _showMessage,
                          ),
                          _DiscoverGroupsTab(
                            groups: discoverGroups,
                            onMessage: _showMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CompactGroupsHeader extends StatelessWidget {
  final TextEditingController searchController;
  final TabController tabController;
  final int myGroupsCount;
  final int discoverCount;

  const _CompactGroupsHeader({
    required this.searchController,
    required this.tabController,
    required this.myGroupsCount,
    required this.discoverCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edu Mate Groups',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'المجموعات الدراسية والتعاون الأكاديمي',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFD7E6FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SmallStatPill(label: 'مجموعاتي', value: '$myGroupsCount'),
              const SizedBox(width: 8),
              _SmallStatPill(label: 'اكتشف', value: '$discoverCount'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'ابحث عن مجموعة أو تخصص...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
              onPressed: searchController.clear,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: AppColors.textOnDark,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'مجموعاتي'),
              Tab(text: 'اكتشف'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallStatPill extends StatelessWidget {
  final String label;
  final String value;

  const _SmallStatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD7E6FF),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyGroupsTab extends StatelessWidget {
  final List<GroupModel> groups;
  final void Function(String text, {Color? color}) onMessage;

  const _MyGroupsTab({required this.groups, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _EmptyState(
        icon: Icons.groups_rounded,
        title: 'لا توجد مجموعات لديك',
        subtitle: 'أنشئ مجموعة جديدة أو انضم إلى مجموعة عامة.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const _SectionTitle(
          title: 'المجموعات المنضم إليها',
          subtitle: 'دخول سريع للمجموعات التي تتابعها',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => _MyGroupCard(
              group: groups[index],
              onMessage: onMessage,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'كل مجموعاتي',
          subtitle: 'المناقشات والملفات والأنشطة',
        ),
        const SizedBox(height: 12),
        ...groups.map(
              (group) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _JoinedGroupCard(group: group),
          ),
        ),
      ],
    );
  }
}

class _DiscoverGroupsTab extends StatelessWidget {
  final List<GroupModel> groups;
  final void Function(String text, {Color? color}) onMessage;

  const _DiscoverGroupsTab({required this.groups, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'لا توجد مجموعات متاحة',
        subtitle: 'جرّب تغيير كلمة البحث أو أنشئ مجموعة جديدة.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const _SectionTitle(
          title: 'مجموعات مقترحة',
          subtitle: 'يمكنك الانضمام فقط، ولا يظهر الدخول قبل العضوية',
        ),
        const SizedBox(height: 12),
        ...groups.map(
              (group) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DiscoverGroupCard(
              group: group,
              onMessage: onMessage,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MyGroupCard extends StatelessWidget {
  final GroupModel group;
  final void Function(String text, {Color? color}) onMessage;

  const _MyGroupCard({required this.group, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final isPrivate = group.type == 'private';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 272,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.blueGlow],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331D4ED8),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _GroupAvatar(group: group, size: 44, onDark: true),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPrivate ? 'خاصة' : 'عامة',
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              group.specializationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD7E6FF),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.lastMessageText.isEmpty
                  ? 'لا توجد رسائل بعد'
                  : group.lastMessageText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniInfo(
                  icon: Icons.people_alt_rounded,
                  text: '${group.membersCount}',
                ),
                const SizedBox(width: 12),
                _MiniInfo(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: '${group.messagesCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinedGroupCard extends StatelessWidget {
  final GroupModel group;

  const _JoinedGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isPrivate = group.type == 'private';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _GroupAvatar(group: group, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      group.specializationName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(
                          label: isPrivate ? 'خاصة' : 'عامة',
                          color:
                          isPrivate ? AppColors.warning : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: '${group.membersCount} عضو',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              group.description.isEmpty
                  ? 'مجموعة أكاديمية للتعاون والنقاش.'
                  : group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailsScreen(group: group),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('التفاصيل'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(group: group),
                      ),
                    );
                  },
                  icon: const Icon(Icons.forum_rounded),
                  label: const Text('الدردشة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoverGroupCard extends StatelessWidget {
  final GroupModel group;
  final void Function(String text, {Color? color}) onMessage;

  const _DiscoverGroupCard({required this.group, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final isPrivate = group.type == 'private';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _GroupAvatar(group: group, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      group.specializationName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(
                          label: isPrivate ? 'خاصة' : 'عامة',
                          color:
                          isPrivate ? AppColors.warning : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: '${group.membersCount} عضو',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              group.description.isEmpty
                  ? 'مجموعة أكاديمية للتعاون والنقاش.'
                  : group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'لا يمكن الدخول للتفاصيل أو الدردشة قبل الانضمام إلى المجموعة.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (isPrivate) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JoinPrivateGroupScreen(group: group),
                    ),
                  );
                  return;
                }

                try {
                  await GroupService.joinGroup(group.docId);
                  onMessage(
                    'تم الانضمام إلى المجموعة',
                    color: AppColors.success,
                  );
                } catch (e) {
                  onMessage(
                    e.toString().replaceFirst('Exception: ', ''),
                    color: AppColors.error,
                  );
                }
              },
              icon: Icon(
                isPrivate ? Icons.key_rounded : Icons.group_add_rounded,
              ),
              label: Text(isPrivate ? 'الانضمام عبر دعوة' : 'انضمام'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textOnDark, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final GroupModel group;
  final double size;
  final bool onDark;

  const _GroupAvatar({
    required this.group,
    this.size = 54,
    this.onDark = false,
  });

  String _initial(String text) {
    if (text.trim().isEmpty) return 'G';
    return text.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (group.groupImageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.30),
          image: DecorationImage(
            image: NetworkImage(group.groupImageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.30),
        gradient: LinearGradient(
          colors: onDark
              ? const [Color(0x33FFFFFF), Color(0x22FFFFFF)]
              : const [AppColors.primary, AppColors.blueGlow],
        ),
      ),
      child: Center(
        child: Text(
          _initial(group.name),
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSpecializationId;
  String? _selectedSpecializationName;
  String _groupType = 'public';
  String? _selectedImagePath;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _selectedImagePath = result.files.single.path!);
    }
  }

  Future<String?> _uploadSelectedImage() async {
    if (_selectedImagePath == null) return null;

    final file = File(_selectedImagePath!);
    final ref = FirebaseStorage.instance
        .ref()
        .child('group_covers')
        .child(
      '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
    );

    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _show('اكتب اسم المجموعة أولًا');
      return;
    }

    if ((_selectedSpecializationId ?? '').isEmpty ||
        (_selectedSpecializationName ?? '').isEmpty) {
      _show('اختر التخصص');
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadSelectedImage();

      await GroupService.createGroup(
        name: name,
        description: description,
        specializationId: _selectedSpecializationId!,
        specializationName: _selectedSpecializationName!,
        type: _groupType,
        groupImageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final previewTitle = _nameController.text.trim().isEmpty
        ? 'اسم المجموعة'
        : _nameController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('إنشاء مجموعة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.blueGlow],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Academic Group',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'أنشئ مساحة عامة أو خاصة للنقاش والتعاون الأكاديمي.',
                  style: TextStyle(
                    color: Color(0xFFD7E6FF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormLabel('معاينة المجموعة'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(18),
                  child: _selectedImagePath != null
                      ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.blueGlow],
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.textOnDark,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _groupType == 'private'
                            ? 'Private Group'
                            : 'Public Group',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusPill(
                        label: _selectedSpecializationName ?? 'اختر التخصص',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel('معلومات المجموعة'),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'اسم المجموعة',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'وصف المجموعة',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('specializations')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final items = snapshot.data?.docs ?? [];

                    return DropdownButtonFormField<String>(
                      value: _selectedSpecializationId,
                      decoration: const InputDecoration(
                        labelText: 'التخصص',
                        prefixIcon: Icon(Icons.school_rounded),
                      ),
                      items: items.map((doc) {
                        final data = doc.data();
                        final id = (data['id'] ?? doc.id).toString();
                        final name = (data['name'] ?? 'بدون اسم').toString();

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name),
                          onTap: () => _selectedSpecializationName = name,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecializationId = value;
                          final matched = items
                              .where((e) =>
                          ((e.data()['id'] ?? e.id).toString() == value))
                              .toList();
                          if (matched.isNotEmpty) {
                            _selectedSpecializationName =
                                (matched.first.data()['name'] ?? '').toString();
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 18),
                const _FormLabel('نوع المجموعة'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TypeSelectorCard(
                        title: 'عامة',
                        subtitle: 'أي طالب يمكنه الانضمام',
                        icon: Icons.public_rounded,
                        selected: _groupType == 'public',
                        onTap: () => setState(() => _groupType = 'public'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeSelectorCard(
                        title: 'خاصة',
                        subtitle: 'الانضمام عبر دعوة فقط',
                        icon: Icons.lock_rounded,
                        selected: _groupType == 'private',
                        onTap: () => setState(() => _groupType = 'private'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _createGroup,
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.check_rounded),
                    label: Text(_loading ? 'جاري الإنشاء...' : 'إنشاء المجموعة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditGroupScreen extends StatefulWidget {
  final GroupModel group;

  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _groupType;
  String? _selectedImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController =
        TextEditingController(text: widget.group.description);
    _groupType = widget.group.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _selectedImagePath = result.files.single.path!);
    }
  }

  Future<String?> _uploadSelectedImage() async {
    if (_selectedImagePath == null) return widget.group.groupImageUrl;

    final file = File(_selectedImagePath!);
    final ref = FirebaseStorage.instance
        .ref()
        .child('group_covers')
        .child(
      '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
    );

    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final imageUrl = await _uploadSelectedImage();

      await GroupService.updateGroup(
        groupId: widget.group.docId,
        name: _nameController.text,
        description: _descriptionController.text,
        type: _groupType,
        groupImageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePreview = _selectedImagePath != null
        ? FileImage(File(_selectedImagePath!)) as ImageProvider
        : widget.group.groupImageUrl.isNotEmpty
        ? NetworkImage(widget.group.groupImageUrl)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تعديل المجموعة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: imagePreview == null
                          ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.blueGlow],
                      )
                          : null,
                      image: imagePreview != null
                          ? DecorationImage(
                        image: imagePreview,
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: imagePreview == null
                        ? const Center(
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: AppColors.textOnDark,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المجموعة',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TypeSelectorCard(
                        title: 'عامة',
                        subtitle: 'يمكن الانضمام مباشرة',
                        icon: Icons.public_rounded,
                        selected: _groupType == 'public',
                        onTap: () => setState(() => _groupType = 'public'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeSelectorCard(
                        title: 'خاصة',
                        subtitle: 'عبر دعوة فقط',
                        icon: Icons.lock_rounded,
                        selected: _groupType == 'private',
                        onTap: () => setState(() => _groupType = 'private'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JoinPrivateGroupScreen extends StatefulWidget {
  final GroupModel group;

  const JoinPrivateGroupScreen({super.key, required this.group});

  @override
  State<JoinPrivateGroupScreen> createState() => _JoinPrivateGroupScreenState();
}

class _JoinPrivateGroupScreenState extends State<JoinPrivateGroupScreen> {
  final TextEditingController _inviteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _inviteController.text.trim();
    if (code.isEmpty) {
      _show('أدخل كود الدعوة');
      return;
    }

    setState(() => _loading = true);

    try {
      await GroupService.joinPrivateGroupWithInvite(
        groupId: widget.group.docId,
        inviteCode: code,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الانضمام إلى المجموعة')),
      );
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الانضمام لمجموعة خاصة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هذه مجموعة خاصة. أدخل كود الدعوة للانضمام.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _inviteController,
                  decoration: const InputDecoration(
                    labelText: 'كود الدعوة',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _join,
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.login_rounded),
                    label: Text(_loading ? 'جاري الانضمام...' : 'انضم الآن'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GroupDetailsScreen extends StatelessWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<String?> _myRole(String ownerId, String groupId) async {
    if (currentUid.isEmpty) return null;
    if (ownerId == currentUid) return 'owner';

    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(currentUid)
        .get();

    if (!doc.exists) return null;
    return (doc.data()?['role'] ?? '').toString();
  }

  bool _canManage(String? role) => role == 'owner' || role == 'admin';
  bool _isOwner(String? role) => role == 'owner';

  Future<void> _copyInvite(
      String inviteCode,
      String groupId,
      BuildContext context,
      ) async {
    final link = 'edumate://group/$groupId?invite=$inviteCode';
    await Clipboard.setData(ClipboardData(text: link));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الدعوة')),
    );
  }

  Future<void> _leave(String role, String groupId, BuildContext context) async {
    try {
      if (role == 'owner') {
        throw Exception('انقل الملكية أولًا أو احذف المجموعة');
      }

      await GroupService.leaveGroup(groupId);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت مغادرة المجموعة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _delete(String groupId, BuildContext context) async {
    try {
      await GroupService.deleteGroup(groupId);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المجموعة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupRef =
    FirebaseFirestore.instance.collection('groups').doc(group.docId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: groupRef.snapshots(),
      builder: (context, groupSnapshot) {
        final liveGroup = groupSnapshot.hasData &&
            groupSnapshot.data != null &&
            groupSnapshot.data!.exists
            ? GroupModel.fromDoc(groupSnapshot.data!)
            : group;

        return FutureBuilder<String?>(
          future: _myRole(liveGroup.ownerId, liveGroup.docId),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final myRole = roleSnapshot.data;

            if (myRole == null) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(title: const Text('غير مسموح')),
                body: const _EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'لا يمكنك فتح هذه الصفحة',
                  subtitle:
                  'يجب أن تكون عضوًا أو مشرفًا أو مالكًا للمجموعة أولًا.',
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(liveGroup.name),
                actions: [
                  if (_canManage(myRole))
                    IconButton(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditGroupScreen(group: liveGroup),
                          ),
                        );

                        if (updated == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديث المجموعة')),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit_rounded),
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (liveGroup.groupImageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Image.network(
                              liveGroup.groupImageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.blueGlow],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                liveGroup.name.trim().isEmpty
                                    ? 'G'
                                    : liveGroup.name.trim()[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textOnDark,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liveGroup.name,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                liveGroup.description.isEmpty
                                    ? 'لا يوجد وصف للمجموعة.'
                                    : liveGroup.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _InfoChip(
                                    icon: Icons.school_rounded,
                                    text: liveGroup.specializationName,
                                  ),
                                  _InfoChip(
                                    icon: Icons.people_alt_rounded,
                                    text: '${liveGroup.membersCount} عضو',
                                  ),
                                  _InfoChip(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    text: '${liveGroup.messagesCount} رسالة',
                                  ),
                                  _InfoChip(
                                    icon: liveGroup.type == 'private'
                                        ? Icons.lock_rounded
                                        : Icons.public_rounded,
                                    text: liveGroup.type == 'private'
                                        ? 'خاصة'
                                        : 'عامة',
                                  ),
                                ],
                              ),
                              if (liveGroup.type == 'private' &&
                                  liveGroup.inviteCode.isNotEmpty &&
                                  _canManage(myRole)) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => _copyInvite(
                                    liveGroup.inviteCode,
                                    liveGroup.docId,
                                    context,
                                  ),
                                  icon: const Icon(Icons.link_rounded),
                                  label: const Text('نسخ رابط الدعوة'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: groupRef.collection('members').snapshots(),
                      builder: (context, snapshot) {
                        final members = snapshot.data?.docs
                            .map(GroupMemberModel.fromDoc)
                            .toList() ??
                            [];

                        members.sort((a, b) =>
                            _roleRank(a.role).compareTo(_roleRank(b.role)));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الأعضاء',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (members.isEmpty)
                              const Text(
                                'لا يوجد أعضاء بعد',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ...members.map((member) {
                              final isMe = member.uid == currentUid;
                              final ownerCanManage =
                                  _isOwner(myRole) && !isMe && member.role != 'owner';
                              final adminCanManage =
                                  myRole == 'admin' && !isMe && member.role == 'member';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnDark,
                                      child: Text(
                                        member.displayName.isNotEmpty
                                            ? member.displayName[0].toUpperCase()
                                            : 'U',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _roleLabel(member.role),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (ownerCanManage || adminCanManage)
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          try {
                                            if (value == 'make_admin') {
                                              await GroupService.makeAdmin(
                                                liveGroup.docId,
                                                member.uid,
                                              );
                                            } else if (value == 'remove_admin') {
                                              await GroupService.removeAdmin(
                                                liveGroup.docId,
                                                member.uid,
                                              );
                                            } else if (value ==
                                                'transfer_ownership') {
                                              await GroupService.transferOwnership(
                                                groupId: liveGroup.docId,
                                                newOwnerId: member.uid,
                                              );
                                            } else if (value == 'remove_member') {
                                              await GroupService.removeMember(
                                                liveGroup.docId,
                                                member.uid,
                                              );
                                            }

                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('تم تنفيذ العملية'),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  e.toString().replaceFirst(
                                                    'Exception: ',
                                                    '',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          if (_isOwner(myRole) &&
                                              member.role == 'member')
                                            const PopupMenuItem(
                                              value: 'make_admin',
                                              child: Text('تعيين كمشرف'),
                                            ),
                                          if (_isOwner(myRole) &&
                                              member.role == 'admin')
                                            const PopupMenuItem(
                                              value: 'remove_admin',
                                              child: Text('إزالة الإشراف'),
                                            ),
                                          if (_isOwner(myRole) &&
                                              member.role != 'owner')
                                            const PopupMenuItem(
                                              value: 'transfer_ownership',
                                              child: Text('نقل الملكية'),
                                            ),
                                          const PopupMenuItem(
                                            value: 'remove_member',
                                            child: Text('طرد من المجموعة'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupChatScreen(group: liveGroup),
                              ),
                            );
                          },
                          icon: const Icon(Icons.forum_rounded),
                          label: const Text('فتح الدردشة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isOwner(myRole))
                    ElevatedButton.icon(
                      onPressed: () => _delete(liveGroup.docId, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textOnDark,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('حذف المجموعة'),
                    ),
                  if (!_isOwner(myRole))
                    OutlinedButton.icon(
                      onPressed: () => _leave(myRole, liveGroup.docId, context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('مغادرة المجموعة'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _roleRank(String role) {
    switch (role) {
      case 'owner':
        return 0;
      case 'admin':
        return 1;
      default:
        return 2;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'المالك';
      case 'admin':
        return 'مشرف';
      default:
        return 'عضو';
    }
  }
}

class GroupChatScreen extends StatelessWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<String?> _myRole() async {
    if (currentUid.isEmpty) return null;
    if (group.ownerId == currentUid) return 'owner';

    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.docId)
        .collection('members')
        .doc(currentUid)
        .get();

    if (!doc.exists) return null;
    return (doc.data()?['role'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _myRole(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final myRole = roleSnapshot.data;

        if (myRole == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('غير مسموح')),
            body: const _EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'لا يمكنك الدخول للدردشة',
              subtitle: 'يجب أن تكون عضوًا داخل المجموعة أولًا.',
            ),
          );
        }

        return _AllowedGroupChatScreen(group: group);
      },
    );
  }
}

class _AllowedGroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const _AllowedGroupChatScreen({required this.group});

  @override
  State<_AllowedGroupChatScreen> createState() =>
      _AllowedGroupChatScreenState();
}

class _AllowedGroupChatScreenState extends State<_AllowedGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      await GroupService.sendMessage(
        groupId: widget.group.docId,
        text: text,
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _timeLabel(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.docId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailsScreen(group: widget.group),
                ),
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل الرسائل'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'ابدأ أول رسالة',
                    subtitle: 'هذه المجموعة لا تحتوي على رسائل بعد.',
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = MessageModel.fromDoc(docs[index]);
                    final isMe = msg.senderId == _uid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.74,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: isMe
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg.senderName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe
                                    ? AppColors.textOnDark
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            if (msg.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _timeLabel(msg.createdAt!),
                                style: TextStyle(
                                  color: isMe
                                      ? const Color(0xFFD7E6FF)
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupModel {
  final String docId;
  final String groupId;
  final String name;
  final String description;
  final String specializationId;
  final String specializationName;
  final String ownerId;
  final String groupImageUrl;
  final String inviteCode;
  final int membersCount;
  final int adminsCount;
  final int messagesCount;
  final String lastMessageText;
  final String type;
  final String status;
  final DateTime? createdAt;

  GroupModel({
    required this.docId,
    required this.groupId,
    required this.name,
    required this.description,
    required this.specializationId,
    required this.specializationName,
    required this.ownerId,
    required this.groupImageUrl,
    required this.inviteCode,
    required this.membersCount,
    required this.adminsCount,
    required this.messagesCount,
    required this.lastMessageText,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory GroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return GroupModel(
      docId: doc.id,
      groupId: (data['groupId'] ?? doc.id).toString(),
      name: (data['name'] ?? data['groupName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      specializationId: (data['specializationId'] ?? '').toString(),
      specializationName: (data['specializationName'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      groupImageUrl: (data['groupImageUrl'] ?? '').toString(),
      inviteCode: (data['inviteCode'] ?? '').toString(),
      membersCount: _toInt(data['membersCounts']),
      adminsCount: _toInt(data['adminsCount']),
      messagesCount: _toInt(data['messagesCount']),
      lastMessageText: (data['lastMessageText'] ?? '').toString(),
      type: (data['type'] ?? 'public').toString(),
      status: (data['status'] ?? 'active').toString(),
      createdAt: _toDate(data['createdAt']),
    );
  }
}

class GroupMemberModel {
  final String uid;
  final String displayName;
  final String role;

  GroupMemberModel({
    required this.uid,
    required this.displayName,
    required this.role,
  });

  factory GroupMemberModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return GroupMemberModel(
      uid: (data['uid'] ?? doc.id).toString(),
      displayName: (data['displayName'] ?? 'User').toString(),
      role: (data['role'] ?? 'member').toString(),
    );
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return MessageModel(
      messageId: (data['messageId'] ?? doc.id).toString(),
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? 'User').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: _toDate(data['createdAt']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return null;
}
