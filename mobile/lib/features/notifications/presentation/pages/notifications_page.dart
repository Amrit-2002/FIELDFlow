import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type;
  final String? targetTaskId;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.targetTaskId,
    this.read = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Emergency Job Dispatched',
      body: 'Walk-In Freezer Compressor R-404A Leak Repair has been assigned with URGENT priority.',
      time: '15m ago',
      type: 'TASK_ASSIGNED',
      read: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Schedule Reminder',
      body: 'You have 3 high priority tasks scheduled for today. Inspect filter plenum before 11:00 AM.',
      time: '2h ago',
      type: 'REMINDER',
      read: false,
    ),
    NotificationItem(
      id: '3',
      title: 'System Synced',
      body: 'All offline task submissions and notes were successfully merged with central database.',
      time: 'Yesterday',
      type: 'SYSTEM',
      read: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const EmptyStateView(
          title: 'No Notifications',
          message: 'You have no alerts at this time.',
          icon: Icons.notifications_none,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final n in _notifications) {
                  n.read = true;
                }
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _notifications[index];

          Color iconColor = AppColors.accent;
          IconData icon = Icons.info_outline;

          if (item.type == 'TASK_ASSIGNED') {
            iconColor = AppColors.error;
            icon = Icons.assignment_late_outlined;
          } else if (item.type == 'REMINDER') {
            iconColor = AppColors.amber;
            icon = Icons.alarm;
          } else if (item.type == 'SYSTEM') {
            iconColor = AppColors.success;
            icon = Icons.check_circle_outline;
          }

          return Card(
            elevation: item.read ? 0 : 1,
            color: item.read ? null : AppColors.accent.withOpacity(0.04),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.read ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    item.time,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item.body,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
              onTap: () {
                setState(() => item.read = true);
                context.push('/tasks');
              },
            ),
          );
        },
      ),
    );
  }
}

