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
            child: _buildInfoSection(),
          ),
          SliverToBoxAdapter(
            child: _buildMembersSection(),
          ),
          SliverToBoxAdapter(
            child: _buildRecentActivitySection(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 60), // Extra bottom padding
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomComposer(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 24),
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
                right: 20,
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
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 56), // Space for overlapping avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${widget.group.collegeName} • ${widget.group.specializationName}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.group.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      widget.group.isPrivate ? "مجموعة خاصة" : "مجموعة عامة",
                      widget.group.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                      color: widget.group.isPrivate ? AppColors.warning : AppColors.success,
                    ),
                    _buildBadge(
                      "أعضاء المجموعة",
                      Icons.group_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoadingRole) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    List<Widget> buttons = [];

    if (!_isMember) {
      if (widget.group.isPublic) {
        buttons.add(_buildPrimaryButton("انضمام للمجموعة", Icons.group_add_rounded, _joinGroup));
      }
    } else {
      buttons.add(_buildPrimaryButton("فتح الدردشة", Icons.chat_bubble_rounded, _openChat));
    }

    if (_isOwner || _isAdmin) {
      buttons.add(_buildSecondaryButton("إدارة الأعضاء", Icons.people_alt_rounded, () {}));
      buttons.add(_buildSecondaryButton("إعدادات المجموعة", Icons.settings_rounded, () {}));
      
      if (widget.group.isPrivate) {
        buttons.add(_buildIconButton(Icons.copy_rounded, "نسخ رابط المجموعة", () {
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
        buttons.add(_buildIconButton(Icons.share_rounded, "مشاركة الرابط", () {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('خاصية المشاركة غير متاحة حالياً')),
          );
        }));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: buttons.map((b) => Padding(padding: const EdgeInsets.only(left: 10), child: b)).toList(),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                  "الدردشة",
                  widget.group.membersCanChat ? "متاحة لجميع الأعضاء" : "متاحة للردود من قبل المشرفين فقط (للقراءة فقط)",
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
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "الأعضاء",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text("عرض كل الأعضاء", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                _buildMemberPreview("مالك المجموعة", "المالك", AppColors.error),
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
          radius: 20,
          backgroundColor: AppColors.inputFill,
          child: Text(
            name[0],
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 14),
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            role,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    if (!_isMember) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "آخر النشاط",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _openChat,
            borderRadius: BorderRadius.circular(20),
            child: Container(
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "انتقل إلى غرفة المحادثة",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "شارك في التحديثات والنقاشات الأخيرة لهذه المجموعة.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomComposer() {
    if (_isLoadingRole) return const SizedBox.shrink();

    if (!_isMember) return const SizedBox.shrink();

    final bool canChat = widget.group.membersCanChat || _isOwner || _isAdmin;

    if (!canChat) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.campaign_rounded, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'المجموعة للإعلانات فقط. المشرفون هم من يمكنهم الإرسال.',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'اكتب رسالة...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _openChat,
                  child: const Center(
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
