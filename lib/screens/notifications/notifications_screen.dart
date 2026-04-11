import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_notification_model.dart';
import '../../services/notifications_service.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTime(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.timeNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgoParam(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgoParam(diff.inHours);
    if (diff.inDays == 1) return l10n.timeYesterday;
    if (diff.inDays < 7) return l10n.timeDaysAgoParam(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationsService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.notificationsMarkAllReadSuccess),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Text(
              l10n.notificationsMarkAllRead,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotificationModel>>(
        stream: NotificationsService.streamMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const _NotificationsEmptyState();
          }

          final now = DateTime.now();

          final todayItems = items.where((item) {
            return item.timestamp.year == now.year &&
                item.timestamp.month == now.month &&
                item.timestamp.day == now.day;
          }).toList();

          final earlierItems = items.where((item) {
            final isToday = item.timestamp.year == now.year &&
                item.timestamp.month == now.month &&
                item.timestamp.day == now.day;
            return !isToday;
          }).toList();

          return ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (todayItems.isNotEmpty) ...[
                _SectionTitle(title: l10n.notificationsSectionToday),
                const SizedBox(height: 10),
                ...todayItems.map(
                      (item) => SizedBox(
                    width: double.infinity,
                    child: _NotificationTile(
                      item: item,
                      timeLabel: _formatTime(item.timestamp, l10n),
                      onTap: () => NotificationsService.markAsRead(item.id),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (earlierItems.isNotEmpty) ...[
                _SectionTitle(title: l10n.notificationsSectionEarlier),
                const SizedBox(height: 10),
                ...earlierItems.map(
                      (item) => SizedBox(
                    width: double.infinity,
                    child: _NotificationTile(
                      item: item,
                      timeLabel: _formatTime(item.timestamp, l10n),
                      onTap: () => NotificationsService.markAsRead(item.id),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel item;
  final String timeLabel;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = item.badgeColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: item.isRead
                  ? (isDark ? AppColors.surface : Colors.white)
                  : accent.withOpacity(isDark ? 0.10 : 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: item.isRead
                    ? (isDark
                    ? AppColors.border.withOpacity(0.45)
                    : Colors.black12)
                    : accent.withOpacity(0.30),
                width: item.isRead ? 1 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.14)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: item.isRead ? Colors.transparent : accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(22),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withOpacity(0.20),
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.textPrimary
                                              : Colors.black87,
                                          fontSize: 15,
                                          fontWeight: item.isRead
                                              ? FontWeight.w700
                                              : FontWeight.w800,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        timeLabel,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : Colors.black45,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : Colors.black54,
                                    fontSize: 13.2,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? AppColors.border : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.notificationsEmptyTitle,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notificationsEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : Colors.black54,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}