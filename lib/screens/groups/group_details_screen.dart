import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/group_model.dart';
import '../../core/theme/app_colors.dart';
import '../../services/group_service.dart';
import 'group_chat_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingRole = true;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMembershipState();
  }

  Future<void> _loadMembershipState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }

    bool member = false;
    bool owner = widget.group.ownerId == user.uid;
    bool admin = false;

    if (owner) {
      member = true;
    }

    try {
      final memberDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .collection('members')
          .doc(user.uid)
          .get();

      if (memberDoc.exists) {
        member = true;
        final role = memberDoc.data()?['role'] ?? 'member';
        if (role == 'admin') admin = true;
        if (role == 'owner') owner = true;
      }
    } catch (e) {
      // Gracefully continue even if query fails
    }

    if (mounted) {
      setState(() {
        _isMember = member;
        _isOwner = owner;
        _isAdmin = admin;
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    setState(() => _isLoadingRole = true);
    try {
      await GroupService.joinPublicGroup(widget.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الانضمام بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    _loadMembershipState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "الدردشة"),
                    Tab(text: "الأعضاء"),
                    Tab(text: "معلومات المجموعة"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChatTab(),
            _buildMembersTab(),
            _buildInfoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover Area
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.blueGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16, // Arabic friendly
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              // Group Avatar Overlapping
              Positioned(
                bottom: -40,
                right: 20, // Arabic friendly
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage: widget.group.imageUrl.isNotEmpty
                        ? NetworkImage(widget.group.imageUrl)
                        : null,
                    child: widget.group.imageUrl.isEmpty
                        ? Text(
                            widget.group.name.isNotEmpty
                                ? widget.group.name.substring(0, 1).toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50), // Space for overlapping avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.group.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                // Badges
                Row(
                  children: [
                    _buildBadge(
                      widget.group.isPrivate ? "خاصة" : "عامة",
                      widget.group.isPrivate ? Icons.lock_rounded : Icons.public,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge("أعضاء المجموعة", Icons.group_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${widget.group.collegeName} • ${widget.group.specializationName}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoadingRole) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    List<Widget> buttons = [];

    if (!_isMember) {
      if (widget.group.isPublic) {
        buttons.add(_buildPrimaryButton("انضمام", Icons.group_add_rounded, _joinGroup));
      }
    } else {
      buttons.add(_buildPrimaryButton("فتح الدردشة", Icons.chat_bubble_rounded, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupChatScreen(group: widget.group)),
        );
      }));
    }

    if (_isOwner || _isAdmin) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 10));
      buttons.add(_buildSecondaryButton("إدارة المجموعة", Icons.settings_rounded, () {
        // Placeholder for manage group
      }));

      // Copy/Share Link ONLY if owner/admin and private group (or general link if preferred)
      if (widget.group.isPrivate) {
        buttons.add(const SizedBox(width: 10));
        buttons.add(_buildIconButton(Icons.copy_rounded, "نسخ الرابط", () {
          // Attempt to copy invite link or fallback to app link
          String link = '';
          try {
             link = (widget.group as dynamic).inviteLink ?? 'edu_mate://group/${widget.group.id}';
          } catch(e) {
             link = 'edu_mate://group/${widget.group.id}';
          }
          Clipboard.setData(ClipboardData(text: link));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نسخ رابط الدعوة الخاص')),
          );
        }));
        
        buttons.add(const SizedBox(width: 10));
        buttons.add(_buildIconButton(Icons.share_rounded, "مشاركة الرابط", () {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('خاصية المشاركة غير متاحة حالياً')),
          );
        }));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: buttons),
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(
        text,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    if (_isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isMember) {
      return _buildEmptyState(
        icon: Icons.lock_rounded,
        title: "محتوى خاص",
        description: "يجب أن تكون عضواً في المجموعة لرؤية الدردشة.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Placeholder count
      itemBuilder: (context, index) {
        bool isMe = index % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, // Still appropriate depending on locale dir
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  const Text(
                    "اسم العضو",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!isMe) const SizedBox(height: 4),
                Text(
                  "هذه رسالة تجريبية في عرض الدردشة المبسط.",
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "10:00 ص",
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMembersTab() {
    // Keep placeholder content with Arabic structure as instructed
    final List<Map<String, dynamic>> mockMembers = [
      {"name": "أحمد علي", "role": "owner"},
      {"name": "سارة خالد", "role": "admin"},
      {"name": "عمر حسن", "role": "member"},
      {"name": "منى زكي", "role": "member"},
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: mockMembers.length,
      separatorBuilder: (context, index) => const Divider(
        color: AppColors.border,
        height: 1,
        indent: 70, // Adjust indent based on RTL if needed
      ),
      itemBuilder: (context, index) {
        final member = mockMembers[index];
        final role = member["role"];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              member["name"][0],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            member["name"],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            role == 'owner' ? 'المالك' : (role == 'admin' ? 'مشرف' : 'عضو'),
            style: TextStyle(
              fontSize: 11,
              color: role == "owner"
                  ? AppColors.error
                  : role == "admin"
                      ? AppColors.warning
                      : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: (_isOwner || _isAdmin) && role != "owner"
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {},
                  itemBuilder: (context) {
                    return [
                      if (role != "admin")
                        const PopupMenuItem(
                          value: "make_admin",
                          child: Text("تعيين كمشرف"),
                        ),
                      if (role == "admin")
                        const PopupMenuItem(
                          value: "remove_admin",
                          child: Text("إزالة من الإشراف"),
                        ),
                      const PopupMenuItem(
                        value: "remove_member",
                        child: Text(
                          "طرد العضو",
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ];
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            "عن المجموعة",
            widget.group.description,
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            "التفاصيل",
            "• النوع: ${widget.group.isPrivate ? 'مجموعة خاصة' : 'مجموعة عامة'}\n"
            "• الكلية: ${widget.group.collegeName}\n"
            "• التخصص: ${widget.group.specializationName}\n"
            "• تاريخ الإنشاء: ${widget.group.createdAt != null ? '${widget.group.createdAt!.day}/${widget.group.createdAt!.month}/${widget.group.createdAt!.year}' : 'غير متوفر'}",
            Icons.analytics_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _tabBar,
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
