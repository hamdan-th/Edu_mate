import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum AppNotificationType {
  general,
  group,
  library,
  bot,
  system,
}

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final AppNotificationType type;
  final String? senderId;
  final String? groupId;
  final String? postId;
  final String? fileId;
  final String? subType;
  final String? senderName;
  final String? targetName;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.senderId,
    this.groupId,
    this.postId,
    this.fileId,
    this.subType,
    this.senderName,
    this.targetName,
  });

  factory AppNotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return AppNotificationModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] ?? false) as bool,
      type: _mapType((data['type'] ?? 'general').toString()),
      senderId: data['senderId']?.toString(),
      groupId: data['groupId']?.toString(),
      postId: data['postId']?.toString(),
      fileId: data['fileId']?.toString(),
      subType: data['subType']?.toString() ??
          _inferSubType(data['title']?.toString()),
      senderName: data['senderName']?.toString(),
      targetName: data['targetName']?.toString(),
    );
  }

  static String? _inferSubType(String? title) {
    if (title == null) return null;
    if (title.contains('إنشاء المجموعة')) return 'group_created';
    if (title.contains('الانضمام إلى المجموعة')) return 'group_joined';
    if (title.contains('تعليق جديد')) return 'feed_comment_new';
    if (title.contains('رد جديد')) return 'feed_reply_new';
    if (title.contains('الموافقة على ملف')) return 'library_file_approved';
    if (title.contains('رفع ملفك')) return 'library_file_uploaded';
    if (title.contains('ترقيتك إلى مشرف')) return 'group_promoted_admin';
    if (title.contains('إزالة صلاحية الإشراف')) return 'group_demoted_admin';
    if (title.contains('كتمك داخل المجموعة')) return 'group_muted';
    if (title.contains('فك الكتم')) return 'group_unmuted';
    if (title.contains('إزالتك من المجموعة')) return 'group_kicked';
    return null;
  }

  String localizedTitle(AppLocalizations l10n) {
    if (subType == null) return title;

    switch (subType) {
      case 'group_created':
        return l10n.notifGroupCreatedTitle;
      case 'group_joined':
        return l10n.notifGroupJoinedTitle;
      case 'group_joined_private':
        return l10n.notifGroupJoinedPrivateTitle;
      case 'group_ownership_transferred':
        return l10n.notifGroupOwnershipTransferredTitle;
      case 'group_promoted_admin':
        return l10n.notifGroupPromotedAdminTitle;
      case 'group_demoted_admin':
        return l10n.notifGroupDemotedAdminTitle;
      case 'group_muted':
        return l10n.notifGroupMutedTitle;
      case 'group_unmuted':
        return l10n.notifGroupUnmutedTitle;
      case 'group_kicked':
        return l10n.notifGroupKickedTitle;
      case 'feed_comment_new':
        return l10n.notifNewCommentTitle;
      case 'feed_reply_new':
        return l10n.notifNewReplyTitle;
      case 'library_file_approved':
        return l10n.notifLibraryFileApprovedTitle;
      case 'library_file_uploaded':
        return l10n.notifLibraryFileUploadedTitle;
      default:
        return title;
    }
  }

  String localizedBody(AppLocalizations l10n) {
    if (subType == null) return body;

    final target = targetName ?? '...';
    final sender = senderName ?? l10n.groupsDefaultMemberName;

    switch (subType) {
      case 'group_created':
        return l10n.notifGroupCreatedBody(target);
      case 'group_joined':
        return l10n.notifGroupJoinedBody(target);
      case 'group_joined_private':
        return l10n.notifGroupJoinedPrivateBody(target);
      case 'group_ownership_transferred':
        return l10n.notifGroupOwnershipTransferredBody(target);
      case 'group_promoted_admin':
        return l10n.notifGroupPromotedAdminBody(target);
      case 'group_demoted_admin':
        return l10n.notifGroupDemotedAdminBody(target);
      case 'group_muted':
        return l10n.notifGroupMutedBody(target);
      case 'group_unmuted':
        return l10n.notifGroupUnmutedBody(target);
      case 'group_kicked':
        return l10n.notifGroupKickedBody(target);
      case 'feed_comment_new':
        return l10n.notifNewCommentBody(sender);
      case 'feed_reply_new':
        return l10n.notifNewReplyBody(sender);
      case 'library_file_approved':
        return l10n.notifLibraryFileApprovedBody(target);
      case 'library_file_uploaded':
        return l10n.notifLibraryFileUploadedBody(target);
      default:
        return body;
    }
  }

  static AppNotificationType _mapType(String type) {
    switch (type) {
      case 'group':
        return AppNotificationType.group;
      case 'library':
        return AppNotificationType.library;
      case 'bot':
        return AppNotificationType.bot;
      case 'system':
        return AppNotificationType.system;
      default:
        return AppNotificationType.general;
    }
  }

  IconData get icon {
    switch (type) {
      case AppNotificationType.group:
        return Icons.groups_rounded;
      case AppNotificationType.library:
        return Icons.library_books_rounded;
      case AppNotificationType.bot:
        return Icons.smart_toy_rounded;
      case AppNotificationType.system:
        return Icons.settings_suggest_rounded;
      case AppNotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color badgeColor(BuildContext context) {
    switch (type) {
      case AppNotificationType.group:
        return Colors.blue;
      case AppNotificationType.library:
        return const Color(0xFFD4AF37);
      case AppNotificationType.bot:
        return Colors.deepPurple;
      case AppNotificationType.system:
        return Colors.teal;
      case AppNotificationType.general:
        return Colors.grey;
    }
  }
}