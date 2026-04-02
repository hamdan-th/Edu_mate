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

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _isLoadingRole = true;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
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

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupChatScreen(group: widget.group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: _buildMainAction(),
          ),
          SliverToBoxAdapter(
            child: _buildSecondaryActions(),
          ),
          SliverToBoxAdapter(
            child: _buildAboutSection(),
          ),
          SliverToBoxAdapter(
            child: _buildMembersSection(),
          ),
          SliverToBoxAdapter(
            child: _buildBottomAction(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 60), // Extra bottom padding
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Area
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.blueGlow],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            // Group Avatar
            Positioned(
              bottom: -46,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
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
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56), // Space for overlapping avatar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center aligned for better symmetry with avatar
            children: [
              Text(
                widget.group.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${widget.group.collegeName} • ${widget.group.specializationName}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.group.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(
                    widget.group.isPrivate ? "خاصة" : "عامة",
                    widget.group.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                    color: widget.group.isPrivate ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    widget.group.membersCanChat ? "محادثة نشطة" : "إعلانات فقط",
                    widget.group.membersCanChat ? Icons.chat_bubble_outline_rounded : Icons.campaign_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    "أعضاء المجموعة",
                    Icons.group_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, IconData icon, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction() {
    if (_isLoadingRole) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    Widget? actionButton;

    if (!_isMember && widget.group.isPublic) {
      actionButton = _buildPrimaryButton("انضمام للمجموعة", Icons.group_add_rounded, _joinGroup);
    } else if (_isMember) {
      actionButton = _buildPrimaryButton("فتح الدردشة", Icons.chat_bubble_rounded, _openChat);
    }

    if (actionButton == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: actionButton,
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    if (_isLoadingRole) return const SizedBox.shrink();

    List<Widget> items = [];

    items.add(_buildSecondaryActionItem(
      icon: Icons.people_outline_rounded,
      label: "الأعضاء",
      onTap: () {},
    ));

    if (_isOwner || _isAdmin) {
      items.add(_buildSecondaryActionItem(
        icon: Icons.settings_outlined,
        label: "الإعدادات",
        onTap: () {},
      ));

      if (widget.group.isPrivate) {
        items.add(_buildSecondaryActionItem(
          icon: Icons.link_rounded,
          label: "رابط المجموعة",
          onTap: () {
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
          },
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      ),
    );
  }

  Widget _buildSecondaryActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "نبذة عن المجموعة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.description_outlined, "الوصف", widget.group.description.isNotEmpty ? widget.group.description : "لا يوجد وصف لهذه المجموعة."),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),
                _buildInfoRow(Icons.school_outlined, "الكلية", widget.group.collegeName),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),
                _buildInfoRow(Icons.menu_book_outlined, "التخصص", widget.group.specializationName),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),
                _buildInfoRow(
                  Icons.chat_outlined,
                  "حالة الدردشة",
                  widget.group.membersCanChat ? "متاحة لجميع الأعضاء" : "إعلانات فقط (للقراءة)",
                ),
                if (widget.group.createdAt != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.border),
                  ),
                  _buildInfoRow(Icons.calendar_today_outlined, "تاريخ الإنشاء", "${widget.group.createdAt!.day}/${widget.group.createdAt!.month}/${widget.group.createdAt!.year}"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "الأعضاء",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMemberPreview("مالك المجموعة", "مالك", AppColors.error),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border),
                ),
                _buildMemberPreview("عضو פעتد", "مشرف", AppColors.warning),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border),
                ),
                _buildMemberPreview("طالب نشط", "عضو", AppColors.textSecondary),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border.withOpacity(0.8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("عرض كل الأعضاء", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPreview(String name, String role, Color roleColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.inputFill,
          child: Text(
            name[0],
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            role,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    if (_isLoadingRole || !_isMember) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
          label: const Text(
            "فتح غرفة الدردشة",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
