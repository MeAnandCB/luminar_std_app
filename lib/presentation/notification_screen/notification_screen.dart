import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/widgets/status_screens.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NotificationApp());
}

class NotificationApp extends StatelessWidget {
  const NotificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifications',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.statsGreen,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: Color(0xFFF8F9FF),
        useMaterial3: true,
      ),
      home: const NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationItem> _allNotifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApiNotifications();
      _loadPaymentNotifications();
    });
  }

  // ── Load notifications from dashboard API data ─────────────────────────────
  void _loadApiNotifications() {
    final controller = Provider.of<DashboardController>(context, listen: false);
    final summary = controller.dashboard?.notificationsSummary;
    if (summary == null) return;

    final List<NotificationItem> items = [];

    bool isDuplicate(NotificationItem item) =>
        items.any((e) => e.id == item.id || (e.title == item.title && e.message == item.message));

    // Urgent notifications first (de-duped)
    for (final raw in summary.urgentNotifications ?? []) {
      final item = _parseRawNotification(raw, urgent: true);
      if (item != null && !isDuplicate(item)) items.add(item);
    }

    // Recent notifications (skip duplicates)
    for (final raw in summary.recentNotifications ?? []) {
      final item = _parseRawNotification(raw, urgent: false);
      if (item != null && !isDuplicate(item)) items.add(item);
    }

    if (items.isNotEmpty && mounted) {
      setState(() => _allNotifications.insertAll(0, items));
    }
  }

  NotificationItem? _parseRawNotification(dynamic raw, {required bool urgent}) {
    if (raw is! Map<String, dynamic>) return null;

    final id = raw['uid']?.toString() ?? raw['id']?.toString() ?? '';
    final title = raw['title']?.toString() ??
        raw['subject']?.toString() ??
        'Notification';
    final message = raw['message']?.toString() ??
        raw['body']?.toString() ??
        raw['content']?.toString() ??
        '';
    final isRead = raw['is_read'] as bool? ?? false;
    final createdAt =
        raw['created_at']?.toString() ?? raw['timestamp']?.toString() ?? '';
    final typeStr =
        raw['notification_type']?.toString() ?? raw['type']?.toString() ?? '';

    // Skip if there's nothing meaningful to show
    if (message.isEmpty && title == 'Notification') return null;

    return NotificationItem(
      id: id.isEmpty ? 'api_${title.hashCode}_${message.hashCode}' : id,
      title: title,
      message: message,
      time: _formatNotifTime(createdAt),
      type: _resolveNotifType(typeStr),
      isRead: isRead,
      icon: urgent
          ? Icons.priority_high_rounded
          : Icons.notifications_rounded,
      color: urgent ? const Color(0xFFFF7675) : AppColors.primary,
      actionUrl: raw['action_url']?.toString() ?? '',
    );
  }

  String _formatNotifTime(String raw) {
    if (raw.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return raw;
    }
  }

  NotificationType _resolveNotifType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pay') || t.contains('fee')) return NotificationType.payments;
    if (t.contains('class') || t.contains('live') || t.contains('session')) {
      return NotificationType.classes;
    }
    return NotificationType.announcements;
  }

  Future<void> _loadPaymentNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('payment_emi_data');
    if (raw == null) return;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final installments = (data['installments'] as List<dynamic>?) ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('dd MMM yyyy');

    final List<NotificationItem> paymentNotifs = [];

    for (final emi in installments) {
      final status = (emi['status'] as String? ?? '').toLowerCase();
      if (status == 'paid') continue;

      final dueDateStr = emi['due_date'] as String? ?? '';
      if (dueDateStr.isEmpty) continue;
      final dueDate = DateTime.tryParse(dueDateStr);
      if (dueDate == null) continue;

      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysUntil = dueDay.difference(today).inDays;
      final isOverdue = emi['is_overdue'] as bool? ?? false;
      final number = emi['number'] as int? ?? 0;
      final amount = (emi['pending'] as num? ?? 0).toDouble();
      final uid = emi['uid'] as String? ?? '';
      final dateStr = fmt.format(dueDate);

      if (isOverdue || status == 'overdue' || daysUntil < 0) {
        paymentNotifs.add(
          NotificationItem(
            id: 'payment_overdue_$uid',
            title: 'Payment Overdue',
            message:
                'Installment #$number of ₹${amount.toStringAsFixed(0)} was due on $dateStr. Please pay immediately.',
            time: 'Overdue',
            type: NotificationType.payments,
            isRead: false,
            icon: Icons.warning_rounded,
            color: const Color(0xFFFF7675),
            actionUrl: '/payments',
          ),
        );
      } else if (daysUntil <= 2) {
        final whenStr = daysUntil == 0
            ? 'today'
            : daysUntil == 1
            ? 'tomorrow'
            : 'in 2 days';
        paymentNotifs.add(
          NotificationItem(
            id: 'payment_due_$uid',
            title: 'Payment Due Soon',
            message:
                'Installment #$number of ₹${amount.toStringAsFixed(0)} is due $whenStr ($dateStr).',
            time: 'Due $whenStr',
            type: NotificationType.payments,
            isRead: false,
            icon: Icons.schedule_rounded,
            color: AppColors.statsOrange,
            actionUrl: '/payments',
          ),
        );
      }
    }

    if (paymentNotifs.isNotEmpty && mounted) {
      setState(() {
        _allNotifications.removeWhere(
          (n) =>
              n.id.startsWith('payment_due_') ||
              n.id.startsWith('payment_overdue_'),
        );
        _allNotifications.insertAll(0, paymentNotifs);
      });
    }
  }

  int get _unreadCount => _allNotifications.where((n) => !n.isRead).length;

  void _markAsRead(String id) {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotifications[index].isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Simple Header
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.splashGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteWithOpacity20,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  if (_unreadCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteWithOpacity20,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle_rounded,
                            color: Color(0xFFFF7675),
                            size: 8,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '$_unreadCount New',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Notifications List
            Expanded(
              child: _allNotifications.isEmpty
                  ? EmptyStateScreen(
                      title: 'No Notifications',
                      message:
                          "You're all caught up! Check back later for updates.",
                      icon: Icons.notifications_none_rounded,
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _allNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _allNotifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color(0xFFFF7675),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.white,
          size: 30,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _allNotifications.removeWhere((n) => n.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification dismissed'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.primary,
              onPressed: () {
                setState(() {
                  _allNotifications.insert(0, notification);
                });
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          _showNotificationDetails(notification);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: notification.color.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: !notification.isRead
                ? Border.all(
                    color: notification.color.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with gradient background
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      notification.color.withValues(alpha: 0.2),
                      notification.color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: notification.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.activitySubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        SizedBox(width: 4),
                        Text(notification.time, style: AppTextStyles.caption),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: notification.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: notification.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    notification.color,
                    notification.color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.whiteWithOpacity50,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.whiteWithOpacity20,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notification.icon,
                      color: AppColors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    notification.time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.whiteWithOpacity80,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    // Container(
                    //   padding: EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.scaffoldBackground,
                    //     borderRadius: BorderRadius.circular(16),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(
                    //         Icons.info_outline_rounded,
                    //         color: notification.color,
                    //         size: 20,
                    //       ),
                    //       SizedBox(width: 12),
                    //       Expanded(
                    //         child: Text(
                    //           'Tap to view related content',
                    //           style: AppTextStyles.caption.copyWith(
                    //             fontSize: 13,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: notification.color,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(
                          color: notification.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text('Close'),
                    ),
                  ),
                  // SizedBox(width: 12),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       Navigator.pop(context);
                  //       // Navigate to relevant screen
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text('Opening ${notification.actionUrl}'),
                  //           behavior: SnackBarBehavior.floating,
                  //         ),
                  //       );
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: notification.color,
                  //       foregroundColor: AppColors.white,
                  //       padding: EdgeInsets.symmetric(vertical: 16),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(30),
                  //       ),
                  //     ),
                  //     child: Text('View'),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.announcements:
        return 'ANNOUNCEMENT';
      case NotificationType.classes:
        return 'CLASS';
      case NotificationType.payments:
        return 'PAYMENT';
    }
  }
}

enum NotificationType { announcements, classes, payments }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;
  final IconData icon;
  final Color color;
  final String actionUrl;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
    required this.icon,
    required this.color,
    required this.actionUrl,
  });
}
