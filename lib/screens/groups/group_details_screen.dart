import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/group_message_model.dart';
import '../../models/group_model.dart';
import '../../core/theme/app_colors.dart';
import '../../services/group_service.dart';
import 'group_chat_screen.dart';
import 'create_group_feed_post_screen.dart';
import 'invite_group_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;
  final bool startEditing;

  const GroupDetailsScreen({super.key, required this.group, this.startEditing = false});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _isLoadingRole = true;
  bool _isJoining = false;
  bool _isMember = false;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isEditing = false;
  bool _isNotificationMuted = false;
  
  late String _groupName;
  late String _groupDescription;
  int _membersCount = 0;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startEditing;
    _groupName = widget.group.name;
    _groupDescription = widget.group.description;
    
    _nameController.text = _groupName;
    _descController.text = _groupDescription;
    _loadMembershipState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadMembershipState() async {
    final state = await GroupService.getUserGroupState(widget.group.id);

    if (mounted) {
      setState(() {
        _isMember = state.isMember;
        _isOwner = state.isOwner;
        _isAdmin = state.isAdmin;
        _membersCount = widget.group.membersCounts;
        _isNotificationMuted = state.notificationsMuted;
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _joinPublicGroup() async {
    setState(() => _isJoining = true);
    try {
      await GroupService.joinPublicGroup(widget.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام للمجموعة بنجاح')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GroupChatScreen(group: widget.group)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _saveEdits() async {
    final newName = _nameController.text.trim();
    final newDesc = _descController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم المجموعة مطلوب')));
      return;
    }

    try {
      await _firestore.collection('groups').doc(widget.group.id).update({
        'name': newName,
        'description': newDesc,
      });

      if (mounted) {
        setState(() {
          _groupName = newName;
          _groupDescription = newDesc;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ')));
      }
    }
  }

  void _toggleMute() async {
    setState(() {
      _isNotificationMuted = !_isNotificationMuted;
    });
    
    if (!_isMember) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('groups').doc(widget.group.id).collection('members').doc(user.uid).update({
          'notificationsMuted': _isNotificationMuted
        });
      }
    } catch (e) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isNotificationMuted ? 'تم كتم الإشعارات' : 'تم تفعيل الإشعارات')),
    );
  }

  Future<void> _leaveGroup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المالك لا يمكنه المغادرة، قم بنقل الملكية أولاً')));
      return;
    }

    try {
      await GroupService.leaveGroup(widget.group.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت المغادرة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء مغادرة المجموعة')));
      }
    }
  }

  Future<void> _transferOwnership(String newOwnerId) async {
    final oldOwnerId = _auth.currentUser?.uid;
    if (oldOwnerId == null) return;

    try {
      WriteBatch batch = _firestore.batch();
      final groupRef = _firestore.collection('groups').doc(widget.group.id);
      batch.update(groupRef, {'ownerId': newOwnerId});
      final oldOwnerRef = groupRef.collection('members').doc(oldOwnerId);
      batch.update(oldOwnerRef, {'role': 'admin'});
      final newOwnerRef = groupRef.collection('members').doc(newOwnerId);
      batch.update(newOwnerRef, {'role': 'owner'});
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نقل الملكية بنجاح')));
        _loadMembershipState(); // reload local flags
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء نقل الملكية')));
    }
  }

  void _handleMemberAction(String action, Map<String, dynamic> memberData, String memberId) async {
    if (memberId == _auth.currentUser?.uid) return;

    try {
      switch (action) {
        case 'make_admin':
          await GroupService.promoteToAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيين المشرف')));
          break;
        case 'remove_admin':
          await GroupService.removeAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إزالة المشرف')));
          break;
        case 'mute':
          await GroupService.muteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم كتم العضو')));
          break;
        case 'unmute':
          await GroupService.unmuteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء كتم العضو')));
          break;
        case 'report':
          await GroupService.reportMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ لمدير التطبيق')));
          break;
        case 'kick':
          await GroupService.kickMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم طرد العضو')));
          break;
        case 'transfer_owner':
          await _transferOwnership(memberId);
          break;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  Widget _buildPopupMenu(String memberId, Map<String, dynamic> data, bool isTargetOwner, bool isTargetAdmin) {
    final status = data['status'] ?? 'active';
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) => _handleMemberAction(action, data, memberId),
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        bool canManage = false;
        if (_isOwner && !isTargetOwner) canManage = true;
        if (_isAdmin && !isTargetOwner && !isTargetAdmin) canManage = true;

        if (canManage) {
          if (_isOwner && !isTargetOwner) {
            if (isTargetAdmin) {
              items.add(const PopupMenuItem(value: 'remove_admin', child: Text("إزالة من الإشراف", style: TextStyle(fontWeight: FontWeight.bold))));
            } else {
              items.add(const PopupMenuItem(value: 'make_admin', child: Text("تعيين كمشرف", style: TextStyle(fontWeight: FontWeight.bold))));
            }
          }

          if (status == 'muted') {
            items.add(const PopupMenuItem(value: 'unmute', child: Text("إلغاء الكتم", style: TextStyle(fontWeight: FontWeight.bold))));
          } else {
            items.add(const PopupMenuItem(value: 'mute', child: Text("كتم العضو", style: TextStyle(fontWeight: FontWeight.bold))));
          }

          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(value: 'kick', child: Text("طرد العضو", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));
        }

        if (items.isNotEmpty) items.add(const PopupMenuDivider());
        items.add(const PopupMenuItem(value: 'report', child: Text("إبلاغ", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));

        if (_isOwner && !isTargetOwner) {
          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(value: 'transfer_owner', child: Text("نقل الملكية", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900))));
        }

        return items;
      },
    );
  }

  Future<void> _reportGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد البلاغ", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("هل أنت متأكد من رغبتك في الإبلاغ عن هذه المجموعة؟ سيتم مراجعة محتواها من قبل الإدارة."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("إبلاغ", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('reports').doc('group_reports').collection('reports').add({
          'groupId': widget.group.id,
          'reporterUserId': user.uid,
          'reportedAt': FieldValue.serverTimestamp(),
          'targetType': 'group',
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام البلاغ وسيتم مراجعته')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إرسال البلاغ')));
    }
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("مسح سجل الدردشة", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        content: const Text("هل أنت متأكد من مسح جميع رسائل الدردشة؟ هذا الإجراء لا يمكن التراجع عنه."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("مسح", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    try {
      await GroupService.clearGroupChat(widget.group.id);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح سجل الدردشة بنجاح')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء مسح السجل')));
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomSheetTheme.backgroundColor ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.white),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.report_problem_rounded, color: AppColors.textPrimary),
                title: const Text("إبلاغ", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _reportGroup();
                },
              ),
              if (_isOwner)
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.error),
                  title: const Text("مسح سجل الدردشة", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _clearChatHistory();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppColors.textPrimary),
                title: const Text("نسخ الرابط", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  String link = widget.group.inviteLink.isEmpty 
                      ? GroupService.buildInviteLink(groupId: widget.group.id, inviteCode: widget.group.inviteCode) 
                      : widget.group.inviteLink;
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
                },
              ),
              
              if (_isOwner || _isAdmin) ...[
                const Divider(color: AppColors.background, thickness: 8),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
                  title: const Text("تعديل المجموعة", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isEditing = true);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => setState(() => _isEditing = false),
          ),
          title: const Text("تعديل", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: _saveEdits,
              child: const Text("حفظ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "اسم المجموعة",
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "الوصف",
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
    ));
    }

    if (_isLoadingRole) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_isMember) {
      return _buildPreviewView();
    }

    return _buildMemberView();
  }

  Widget _buildPreviewView() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: (Theme.of(context).brightness == Brightness.dark ? AppColors.background : const Color(0xFFF8F9FA)),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56, bottom: 40),
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                child: widget.group.imageUrl.isEmpty
                    ? Text(
                        _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$_membersCount عضو",
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.group.collegeName} • ${widget.group.specializationName}",
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.group.isPublic ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.group.isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 14, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      widget.group.isPublic ? "مجموعة عامة" : "مجموعة خاصة",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_groupDescription.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _groupDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isJoining ? null : _joinPublicGroup,
                    child: _isJoining
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("انضمام للمجموعة", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberView() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Container(
                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.background : const Color(0xFFF8F9FA)),
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 48, bottom: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                        child: widget.group.imageUrl.isEmpty
                            ? Text(
                                _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'M',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _groupName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$_membersCount عضو",
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      if (_groupDescription.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _groupDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionItem(_isNotificationMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded, _isNotificationMuted ? "تفعيل" : "كتم", _toggleMute),
                          _buildActionItem(Icons.exit_to_app_rounded, "مغادرة", _leaveGroup, color: AppColors.error),
                          _buildActionItem(Icons.more_horiz_rounded, "المزيد", _openMoreMenu),
                        ],
                      ),
                      if (widget.group.isPublic && (_isOwner || _isAdmin)) ...[
                        const SizedBox(height: 16),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore.collection('groups').doc(widget.group.id).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                            final canChat = data['membersCanChat'] ?? true;

                            return Column(
                              children: [
                                if (widget.group.isPublic) ...[
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary, Color(0xFF8A4DFF)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupFeedPostScreen(group: widget.group)));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                                              ),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("نشر في الفيد العام", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                                                    SizedBox(height: 2),
                                                    Text("مشاركة إعلان أو تحديث لجميع الطلاب", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                SwitchListTile(
                                  title: const Text("السماح للأعضاء بالمشاركة في الدردشة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                  activeThumbColor: AppColors.primary,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                  value: canChat,
                                  onChanged: (val) => _firestore.collection('groups').doc(widget.group.id).update({'membersCanChat': val}),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  Container(
                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.background : const Color(0xFFF8F9FA)),
                    child: const TabBar(
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: [
                        Tab(text: "الأعضاء"),
                        Tab(text: "الوسائط"),
                        Tab(text: "الروابط"),
                        Tab(text: "المحفوظات"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.background : const Color(0xFFF8F9FA)),
            child: TabBarView(
              children: [
                _KeepAlivePage(child: _buildMembersTab()),
                _KeepAlivePage(child: _buildMediaTab()),
                _KeepAlivePage(child: _buildLinksTab()),
                _KeepAlivePage(child: _buildSavedMessagesTab()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {Color color = AppColors.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (!_isMember) {
      return _buildEmptyState(Icons.lock_rounded, "يجب الانضمام للمجموعة لرؤية الأعضاء");
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').doc(widget.group.id).collection('members').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState(Icons.error_outline_rounded, "حدث خطأ أثناء تحميل الأعضاء");
        }

        final List<DocumentSnapshot> docs = List.from(snapshot.data?.docs ?? []);
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.group_rounded, "لا يوجد أعضاء في هذه المجموعة");
        }

        docs.sort((a, b) {
          final roleA = (a.data() as Map<String, dynamic>)['role'] ?? 'member';
          final roleB = (b.data() as Map<String, dynamic>)['role'] ?? 'member';
          int weight(String r) {
            if (r == 'owner') return 0;
            if (r == 'admin') return 1;
            return 2;
          }
          return weight(roleA).compareTo(weight(roleB));
        });

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            String name = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? 'عضو').trim();
            if (name.contains('@')) name = name.split('@').first;
            final imageUrl = data['imageUrl'] ?? data['photoUrl'];
            final role = data['role'] ?? 'member';
            final status = data['status'] ?? 'active';

            String roleStr = "عضو";
            Color roleCol = AppColors.primary;
            Widget roleIcon = const SizedBox.shrink();

            if (role == 'owner') {
              roleStr = "مالك";
              roleCol = AppColors.error;
              roleIcon = const Icon(Icons.workspace_premium, color: Colors.purple, size: 18);
            } else if (role == 'admin') {
              roleStr = "مشرف";
              roleCol = AppColors.warning;
              roleIcon = const Icon(Icons.headset_mic, color: Colors.orange, size: 18);
            }

            String statusStr = status == 'muted' ? " (مكتوم)" : (status == 'banned' ? " (محظور)" : "");

            final memberId = docs[index].id;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(name.isNotEmpty ? name[0] : 'M', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Row(
                children: [
                  Flexible(child: Text(name + statusStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(width: 6),
                  roleIcon,
                ],
              ),
              subtitle: Text(roleStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (role != 'member') Text(roleStr, style: TextStyle(color: roleCol, fontWeight: FontWeight.w900, fontSize: 12)),
                  if (memberId != _auth.currentUser?.uid) ...[
                    if (role != 'member') const SizedBox(width: 8),
                    _buildPopupMenu(memberId, data, role == 'owner', role == 'admin'),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedMessagesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: GroupService.streamSavedMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("حدث خطأ في تحميل المحفوظات", style: TextStyle(color: AppColors.textSecondary)));
        }
        
        final msgs = snapshot.data ?? [];
        if (msgs.isEmpty) {
          return _buildEmptyState(Icons.bookmark_rounded, "لا توجد رسائل محفوظة");
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: msgs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
          itemBuilder: (context, index) {
            final msg = msgs[index];
            final timestamp = msg['createdAt'] as Timestamp?;
            final dateStr = timestamp != null ? "${timestamp.toDate().day}/${timestamp.toDate().month} - ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}" : "";
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: AppColors.warning, size: 22),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(msg['senderName'] ?? 'عضو', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(msg['text'] ?? 'رسالة', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87), fontSize: 14, height: 1.4)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return StreamBuilder<List<GroupMessageModel>>(
      stream: GroupService.streamMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (snapshot.hasError) return const Center(child: Text("خطأ في تحميل الوسائط", style: TextStyle(color: AppColors.textSecondary)));

        final msgs = snapshot.data ?? [];
        final mediaMsgs = msgs.where((m) => m.imageUrl != null && m.imageUrl!.isNotEmpty).toList();

        if (mediaMsgs.isEmpty) return _buildEmptyState(Icons.photo_library_rounded, "لا توجد وسائط");

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: mediaMsgs.length,
          itemBuilder: (context, index) {
            final url = mediaMsgs[index].imageUrl!;
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.border.withOpacity(0.05) : Colors.black12)),
                errorBuilder: (context, error, stack) => Container(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.white), child: const Icon(Icons.broken_image, color: AppColors.textSecondary)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLinksTab() {
    return StreamBuilder<List<GroupMessageModel>>(
      stream: GroupService.streamMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (snapshot.hasError) return const Center(child: Text("خطأ في تحميل الروابط", style: TextStyle(color: AppColors.textSecondary)));

        final RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+|edumate:\/\/[^\s]+)', caseSensitive: false);
        final msgs = snapshot.data ?? [];
        
        // Filter messages that contain a link
        final linkMsgs = msgs.where((m) => urlRegExp.hasMatch(m.text)).toList();

        if (linkMsgs.isEmpty) return _buildEmptyState(Icons.link_rounded, "لا توجد روابط");

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: linkMsgs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
          itemBuilder: (context, index) {
            final msg = linkMsgs[index];
            final match = urlRegExp.firstMatch(msg.text);
            final url = match?.group(0) ?? '';
            
            final timestamp = msg.createdAt;
            final dateStr = timestamp != null ? "${timestamp.day}/${timestamp.month} - ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}" : "";
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 22),
              ),
              title: Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              trailing: dateStr.isNotEmpty ? Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)) : null,
              onTap: () {
                if (url.startsWith('edumate://invite')) {
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    final groupId = uri.queryParameters['groupId'];
                    final code = uri.queryParameters['code'];
                    if (groupId != null && groupId.isNotEmpty && code != null && code.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => InviteGroupScreen(groupId: groupId, code: code)));
                      return;
                    }
                  }
                }
                // Future enhancement: launchUrl(Uri.parse(url))
              },
            );
          },
        );
      },
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate(this.child);

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
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
