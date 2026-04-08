import 'package:flutter/material.dart';

enum NotificationType {
  general,
  group,
  library,
  bot,
  system,
}

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.group:
        return Icons.groups_rounded;
      case NotificationType.library:
        return Icons.library_books_rounded;
      case NotificationType.bot:
        return Icons.smart_toy_rounded;
      case NotificationType.system:
        return Icons.settings_suggest_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color badgeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case NotificationType.group:
        return colorScheme.primary;
      case NotificationType.library:
        return const Color(0xFFD4AF37);
      case NotificationType.bot:
        return const Color(0xFF7C4DFF);
      case NotificationType.system:
        return const Color(0xFF26A69A);
      case NotificationType.general:
        return colorScheme.secondary;
    }
  }
}