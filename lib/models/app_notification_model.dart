import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    );
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