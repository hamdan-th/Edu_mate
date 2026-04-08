import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification_item_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItemModel> _items;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    _items = [
      NotificationItemModel(
        id: '1',
        title: 'تمت الموافقة على ملفك',
        body: 'تم قبول ملف "شبكات الحاسوب" وإتاحته داخل المكتبة.',
        timestamp: now.subtract(const Duration(minutes: 18)),
        isRead: false,
        type: NotificationType.library,
      ),
      NotificationItemModel(
        id: '2',
        title: 'رسالة جديدة في المجموعة',
        body: 'هناك رسالة جديدة في مجموعة "مشروع التخرج".',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
        type: NotificationType.group,
      ),
      NotificationItemModel(
        id: '3',
        title: 'إعجاب جديد بمنشورك',
        body: 'أحد الأعضاء أعجب بمنشورك الأخير في الصفحة الرئيسية.',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
        type: NotificationType.general,
      ),
      NotificationItemModel(
        id: '4',
        title: 'اقتراح من Edu Bot',
        body: 'لديك توصية جديدة لمراجع مرتبطة بتخصصك.',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
        type: NotificationType.bot,
      ),
      NotificationItemModel(
        id: '5',
        title: 'تحديث في النظام',
        body: 'تم تحسين تجربة المكتبة والوضع الداكن بنجاح.',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        isRead: true,
        type: NotificationType.system,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      _items = _items.map((e) => e.copyWith(isRead: true)).toList();
    });
  }

  void _markOneAsRead(String id) {
    setState(() {
      _items = _items
          .map((e) => e.id == id ? e.copyWith(isRead: true) : e)
          .toList();
    });
  }

  List<NotificationItemModel> get _todayItems {
    final now = DateTime.now();
    return _items.where((item) {
      return item.timestamp.year == now.year &&
          item.timestamp.month == now.month &&
          item.timestamp.day == now.day;
    }).toList();
  }

  List<NotificationItemModel> get _earlierItems {
    final now = DateTime.now();
    return _items.where((item) {
      final isToday = item.timestamp.year == now.year &&
          item.timestamp.month == now.month &&
          item.timestamp.day == now.day;
      return !isToday;
    }).toList();
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _items.where((e) => !e.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإشعارات',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unreadCount > 0
                  ? 'لديك $unreadCount إشعارات غير مقروءة'
                  : 'كل الإشعارات مقروءة',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : Colors.black54,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_items.any((e) => !e.isRead))
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'تحديد الكل كمقروء',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const _NotificationsEmptyState()
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (_todayItems.isNotEmpty) ...[
            const _SectionTitle(title: 'اليوم'),
            const SizedBox(height: 10),
            ..._todayItems.map(
                  (item) => _NotificationTile(
                item: item,
                timeLabel: _formatTime(item.timestamp),
                onTap: () => _markOneAsRead(item.id),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (_earlierItems.isNotEmpty) ...[
            const _SectionTitle(title: 'الأقدم'),
            const SizedBox(height: 10),
            ..._earlierItems.map(
                  (item) => _NotificationTile(
                item: item,
                timeLabel: _formatTime(item.timestamp),
                onTap: () => _markOneAsRead(item.id),
              ),
            ),
          ],
        ],
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
  final NotificationItemModel item;
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
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.isRead
                    ? (isDark
                    ? AppColors.border.withOpacity(0.55)
                    : Colors.black12)
                    : accent.withOpacity(0.30),
                width: item.isRead ? 1 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.16)
                      : Colors.black.withOpacity(0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withOpacity(0.18),
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
                          Text(
                            timeLabel,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : Colors.black45,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
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
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.border : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary.withOpacity(0.10),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد إشعارات الآن',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عندما يصلك تفاعل جديد أو تحديث مهم سيظهر هنا بشكل مرتب وواضح.',
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