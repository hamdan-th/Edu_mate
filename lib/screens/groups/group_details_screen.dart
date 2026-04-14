import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/group_message_model.dart';
import '../../models/group_model.dart';
import 'package:provider/provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../widgets/guest_action_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../services/group_service.dart';
import 'group_chat_screen.dart';
import 'create_group_feed_post_screen.dart';
import 'invite_group_screen.dart';
import '../../l10n/app_localizations.dart';
import 'group_profile_screen.dart';
import '../../widgets/feed/post_card_wrapper.dart';
import '../../widgets/common/premium_transitions.dart';
import '../../services/upload_screening_service.dart';

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

  File? _pickedImage;
  late String _currentImageUrl;
  bool _removeImage = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startEditing;
    _groupName = widget.group.name;
    _groupDescription = widget.group.description;
    
    _nameController.text = _groupName;
    _descController.text = _groupDescription;
    _currentImageUrl = widget.group.imageUrl;
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
    // 🚫 Guest cannot join groups
    if (context.read<GuestProvider>().isGuest) {
      GuestActionDialog.show(
        context,
        title: 'تسجيل الدخول مطلوب',
        subtitle: 'يمكنك مشاهدة المجموعات كضيف، وللانضمام يجب تسجيل الدخول.',
      );
      return;
    }

    setState(() => _isJoining = true);
    try {
      await GroupService.joinPublicGroup(widget.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsJoinSuccess)));
        Navigator.pushReplacement(context, PremiumPageRoute(page: GroupChatScreen(group: widget.group)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _removeImage = false;
      });
    }
  }

  Future<void> _saveEdits() async {
    final newName = _nameController.text.trim();
    final newDesc = _descController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsNameRequired)));
      return;
    }

    try {
      // Determine the new image URL
      String? newImageUrl;          // null  → no change
      String? backfillUrl;          // value to write to posts (may be '')

      if (_pickedImage != null) {
        // Case 1: new image selected
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedImage!.path.split('/').last}';
        final ref = FirebaseStorage.instance.ref().child('group_covers').child(fileName);
        
        // Perform pre-upload screening
        await UploadScreeningService.validate(_pickedImage!, isImage: true);

        await ref.putFile(_pickedImage!);
        newImageUrl = await ref.getDownloadURL();
        backfillUrl = newImageUrl;
      } else if (_removeImage) {
        // Case 2: user explicitly removed the image
        newImageUrl = '';
        backfillUrl = '';
      }
      // Case 3: no change → newImageUrl stays null, no backfill

      final updates = <String, dynamic>{
        'name': newName,
        'description': newDesc,
        if (newImageUrl != null) 'imageUrl': newImageUrl,
        if (newImageUrl != null) 'groupImageUrl': newImageUrl,
      };

      await _firestore.collection('groups').doc(widget.group.id).update(updates);

      // Backfill groupImageUrl in all feed posts belonging to this group
      if (backfillUrl != null) {
        final postsSnap = await _firestore
            .collection('posts')
            .where('groupId', isEqualTo: widget.group.id)
            .get();
        if (postsSnap.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in postsSnap.docs) {
            batch.update(doc.reference, {'groupImageUrl': backfillUrl});
          }
          await batch.commit();
        }
      }

      if (mounted) {
        setState(() {
          _groupName = newName;
          _groupDescription = newDesc;
          if (newImageUrl != null) _currentImageUrl = newImageUrl;
          _pickedImage = null;
          _removeImage = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsSaveSuccess)));
      }
    } catch (e) {
      if (mounted && e is ScreeningException) {
        UploadScreeningService.showScanError(context, e);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsSaveError)));
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
      SnackBar(content: Text(_isNotificationMuted ? AppLocalizations.of(context)!.groupsMuteNotificationsSuccess : AppLocalizations.of(context)!.groupsUnmuteNotificationsSuccess)),
    );
  }

  Future<void> _leaveGroup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsOwnerLeaveError)));
      return;
    }

    try {
      await GroupService.leaveGroup(widget.group.id);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsLeaveSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsLeaveError)));
      }
    }
  }

  Future<void> _transferOwnership(String newOwnerId) async {
    final oldOwnerId = _auth.currentUser?.uid;
    if (oldOwnerId == null) return;

    try {
      await GroupService.transferOwnership(widget.group.id, newOwnerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsTransferOwnershipSuccess)));
        _loadMembershipState(); // reload local flags
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsTransferOwnershipError)));
    }
  }

  void _handleMemberAction(String action, Map<String, dynamic> memberData, String memberId) async {
    if (memberId == _auth.currentUser?.uid) return;

    try {
      switch (action) {
        case 'make_admin':
          await GroupService.promoteToAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsMakeAdminSuccess)));
          break;
        case 'remove_admin':
          await GroupService.removeAdmin(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsRemoveAdminSuccess)));
          break;
        case 'mute':
          await GroupService.muteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsMuteMemberSuccess)));
          break;
        case 'unmute':
          await GroupService.unmuteMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsUnmuteMemberSuccess)));
          break;
        case 'report':
          await GroupService.reportMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsReportMemberSuccess)));
          break;
        case 'kick':
          await GroupService.kickMember(widget.group.id, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsKickMemberSuccess)));
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
        final l10n = AppLocalizations.of(context)!;
        List<PopupMenuEntry<String>> items = [];

        bool canManage = false;
        if (_isOwner && !isTargetOwner) canManage = true;
        if (_isAdmin && !isTargetOwner && !isTargetAdmin) canManage = true;

        if (canManage) {
          if (_isOwner && !isTargetOwner) {
            if (isTargetAdmin) {
              items.add(PopupMenuItem(value: 'remove_admin', child: Text(l10n.groupsActionRemoveAdmin, style: const TextStyle(fontWeight: FontWeight.bold))));
            } else {
              items.add(PopupMenuItem(value: 'make_admin', child: Text(l10n.groupsActionMakeAdmin, style: const TextStyle(fontWeight: FontWeight.bold))));
            }
          }

          if (status == 'muted') {
            items.add(PopupMenuItem(value: 'unmute', child: Text(l10n.groupsActionUnmuteMember, style: const TextStyle(fontWeight: FontWeight.bold))));
          } else {
            items.add(PopupMenuItem(value: 'mute', child: Text(l10n.groupsActionMuteMember, style: const TextStyle(fontWeight: FontWeight.bold))));
          }

          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(value: 'kick', child: Text(l10n.groupsActionKickMember, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));
        }

        if (items.isNotEmpty) items.add(const PopupMenuDivider());
        items.add(PopupMenuItem(value: 'report', child: Text(l10n.groupsActionReport, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))));

        if (_isOwner && !isTargetOwner) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(value: 'transfer_owner', child: Text(l10n.groupsActionTransferOwnership, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900))));
        }

        return items;
      },
    );
  }

  Future<void> _reportGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.groupsReportConfirmTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.groupsReportConfirmMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.profileCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.groupsActionReport, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsReportReceived)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupsReportError)));
    }
  }

  Future<void> _clearChatHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.groupsActionClearChat, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        content: Text(l10n.groupsClearChatConfirmMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.profileCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.groupsClearChatSubmit, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    try {
      await GroupService.clearGroupChat(widget.group.id);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsClearChatSuccess)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsClearChatError)));
    }
  }
  void _openMoreMenu() {
    final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.groupsActionReport, style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _reportGroup();
                },
              ),
              if (_isOwner)
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.error),
                  title: Text(l10n.groupsActionClearChat, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _clearChatHistory();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppColors.textPrimary),
                title: Text(l10n.groupsActionCopyLink, style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  String link = widget.group.inviteLink.isEmpty 
                      ? GroupService.buildInviteLink(groupId: widget.group.id, inviteCode: widget.group.inviteCode) 
                      : widget.group.inviteLink;
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupsCopyLinkSuccess)));
                },
              ),
              
              if (_isOwner || _isAdmin) ...[
                const Divider(color: AppColors.background, thickness: 8),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
                  title: Text(l10n.groupsActionEditGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context)!;
    if (_isEditing) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => setState(() {
              _isEditing = false;
              _pickedImage = null;
              _removeImage = false;
              _currentImageUrl = widget.group.imageUrl;
            }),
          ),
          title: Text(l10n.groupsEditTitle, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: _saveEdits,
              child: Text(l10n.groupsSaveAction, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (_currentImageUrl.isNotEmpty ? NetworkImage(_currentImageUrl) : null),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 20,
                          child: Icon(
                            _pickedImage != null ? Icons.check_rounded : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Remove image button — shown only when there is an image
                  if (_pickedImage != null || _currentImageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _pickedImage = null;
                        _removeImage = true;
                        _currentImageUrl = '';
                      }),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.groupsNameLabel,
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
                  labelText: l10n.groupsDescLabel,
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
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 32, bottom: 40),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _isDark ? null : Border.all(color: Colors.black.withOpacity(0.08), width: 1.5),
                  boxShadow: _isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withOpacity(_isDark ? 0.1 : 0.18),
                  backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                  child: widget.group.imageUrl.isEmpty
                      ? Text(
                          _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _groupName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: _isDark ? AppColors.textPrimary : AppColors.textOnLight
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$_membersCount ${AppLocalizations.of(context)!.groupsMemberCountSuffix}",
                style: TextStyle(
                  fontSize: 16, 
                  color: _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, 
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.group.collegeName} • ${widget.group.specializationName}",
                    style: TextStyle(
                      fontSize: 14, 
                      color: _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary.withOpacity(0.8), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.group.isPublic 
                      ? AppColors.success.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.18) 
                      : AppColors.warning.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.group.isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 14, color: widget.group.isPublic ? AppColors.success : AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      widget.group.isPublic ? AppLocalizations.of(context)!.groupsPublicBadge : AppLocalizations.of(context)!.groupsPrivateBadge,
                      style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.bold, 
                        color: widget.group.isPublic 
                            ? (Theme.of(context).brightness == Brightness.dark ? AppColors.success : const Color(0xFF059669)) 
                            : (Theme.of(context).brightness == Brightness.dark ? AppColors.warning : const Color(0xFFD97706))
                      ),
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
                    style: TextStyle(
                      fontSize: 15, 
                      color: _isDark ? AppColors.textPrimary : AppColors.textOnLight, 
                      height: 1.5, 
                      fontWeight: FontWeight.w500
                    ),
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
                      backgroundColor: _isDark ? AppColors.primary : AppColors.lightPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isJoining ? null : _joinPublicGroup,
                    child: _isJoining
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(AppLocalizations.of(context)!.groupsJoinAction, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GroupProfileScreen(group: widget.group)),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'الملف الشخصي',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDark ? AppColors.background : const Color(0xFFF4F5F8),
                    border: _isDark
                        ? null
                        : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 1)),
                    boxShadow: _isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 28, bottom: 20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: _isDark
                              ? null
                              : Border.all(color: Colors.black.withOpacity(0.10), width: 2),
                          boxShadow: _isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withOpacity(_isDark ? 0.10 : 0.15),
                          backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                          child: widget.group.imageUrl.isEmpty
                              ? Text(
                                  _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'M',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: _isDark ? AppColors.primary : const Color(0xFF5B21B6),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _groupName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _isDark ? AppColors.textPrimary : const Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$_membersCount ${AppLocalizations.of(context)!.groupsMemberCountSuffix}",
                        style: TextStyle(
                          fontSize: 15,
                          color: _isDark ? AppColors.textSecondary : const Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_groupDescription.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _groupDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _isDark ? AppColors.textPrimary : const Color(0xFF374151),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionItem(_isNotificationMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded, _isNotificationMuted ? AppLocalizations.of(context)!.groupsEnableAction : AppLocalizations.of(context)!.groupsMuteAction, _toggleMute),
                          _buildActionItem(Icons.exit_to_app_rounded, AppLocalizations.of(context)!.groupsLeaveAction, _leaveGroup, color: AppColors.error),
                          _buildActionItem(Icons.more_horiz_rounded, AppLocalizations.of(context)!.groupsMoreAction, _openMoreMenu),
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
                                        colors: [AppColors.primary, AppColors.primaryDark],
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
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(AppLocalizations.of(context)!.groupsPublishFeedAction, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                                                    const SizedBox(height: 2),
                                                    Text(AppLocalizations.of(context)!.groupsPublishFeedSub, style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
                                  title: Text(AppLocalizations.of(context)!.groupsAllowMembersChat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
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
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: TabBar(
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.textSecondary 
                          : const Color(0xFF6B7280),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: [
                        Tab(text: AppLocalizations.of(context)!.groupsTabMembers),
                        Tab(text: AppLocalizations.of(context)!.groupsTabMedia),
                        Tab(text: AppLocalizations.of(context)!.groupsTabLinks),
                        Tab(text: AppLocalizations.of(context)!.groupsTabSaved),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isDark ? color.withOpacity(0.12) : color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: _isDark
                  ? Border.all(color: color.withOpacity(0.15))
                  : Border.all(color: color.withOpacity(0.22), width: 1.5),
              boxShadow: _isDark
                  ? null
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _isDark ? color : color.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (!_isMember) {
      return _buildEmptyState(Icons.lock_rounded, AppLocalizations.of(context)!.groupsRequiresJoinToView);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').doc(widget.group.id).collection('members').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState(Icons.error_outline_rounded, AppLocalizations.of(context)!.groupsErrorLoadingMembers);
        }

        final List<DocumentSnapshot> docs = List.from(snapshot.data?.docs ?? []);
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.group_rounded, AppLocalizations.of(context)!.groupsEmptyMembersTitle);
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
            String name = (data['username']?.toString() ?? data['fullName']?.toString() ?? data['displayName']?.toString() ?? data['name']?.toString() ?? AppLocalizations.of(context)!.groupsRoleMember).trim();
            if (name.contains('@')) name = name.split('@').first;
            final imageUrl = data['imageUrl'] ?? data['photoUrl'];
            final role = data['role'] ?? 'member';
            final status = data['status'] ?? 'active';

            String roleStr = AppLocalizations.of(context)!.groupsRoleMember;
            Color roleCol = AppColors.primary;
            Widget roleIcon = const SizedBox.shrink();

            if (role == 'owner') {
              roleStr = AppLocalizations.of(context)!.groupsRoleOwner;
              roleCol = AppColors.error;
              roleIcon = const Icon(Icons.workspace_premium, color: Colors.purple, size: 18);
            } else if (role == 'admin') {
              roleStr = AppLocalizations.of(context)!.groupsRoleAdmin;
              roleCol = AppColors.warning;
              roleIcon = const Icon(Icons.headset_mic, color: Colors.orange, size: 18);
            }

            String statusStr = status == 'muted' ? AppLocalizations.of(context)!.groupsStatusMuted : (status == 'banned' ? AppLocalizations.of(context)!.groupsStatusBanned : "");

            final memberId = docs[index].id;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _isDark
                      ? null
                      : Border.all(color: Colors.black.withOpacity(0.07), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(_isDark ? 0.10 : 0.13),
                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0] : 'M',
                          style: TextStyle(
                            color: _isDark ? AppColors.primary : const Color(0xFF5B21B6),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      name + statusStr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _isDark ? AppColors.textPrimary : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  roleIcon,
                ],
              ),
              subtitle: Text(
                roleStr,
                style: TextStyle(
                  color: _isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (role != 'member')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleCol.withOpacity(_isDark ? 0.12 : 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: roleCol.withOpacity(_isDark ? 0.20 : 0.30), width: 1),
                      ),
                      child: Text(
                        roleStr,
                        style: TextStyle(
                          color: roleCol,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  if (memberId != _auth.currentUser?.uid) ...[
                    if (role != 'member') const SizedBox(width: 6),
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
          return Center(child: Text(AppLocalizations.of(context)!.groupsErrorLoadingSaved, style: const TextStyle(color: AppColors.textSecondary)));
        }
        
        final msgs = snapshot.data ?? [];
        if (msgs.isEmpty) {
          return _buildEmptyState(Icons.bookmark_rounded, AppLocalizations.of(context)!.groupsEmptySavedTitle);
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
                  Expanded(child: Text(msg['senderName'] ?? AppLocalizations.of(context)!.groupsRoleMember, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(msg['text'] ?? AppLocalizations.of(context)!.groupsDefaultMessageLabel, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black87), fontSize: 14, height: 1.4)),
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
        if (snapshot.hasError) return Center(child: Text(AppLocalizations.of(context)!.groupsErrorLoadingMedia, style: const TextStyle(color: AppColors.textSecondary)));

        final msgs = snapshot.data ?? [];
        final mediaMsgs = msgs.where((m) => m.imageUrl != null && m.imageUrl!.isNotEmpty).toList();

        if (mediaMsgs.isEmpty) return _buildEmptyState(Icons.photo_library_rounded, AppLocalizations.of(context)!.groupsEmptyMediaTitle);

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
        if (snapshot.hasError) return Center(child: Text(AppLocalizations.of(context)!.groupsErrorLoadingLinks, style: const TextStyle(color: AppColors.textSecondary)));

        final RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+|edumate:\/\/[^\s]+)', caseSensitive: false);
        final msgs = snapshot.data ?? [];
        
        // Filter messages that contain a link
        final linkMsgs = msgs.where((m) => urlRegExp.hasMatch(m.text)).toList();

        if (linkMsgs.isEmpty) return _buildEmptyState(Icons.link_rounded, AppLocalizations.of(context)!.groupsEmptyLinksTitle);

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
                // Future enhancement: await launchUrl(Uri.parse(url));
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
