import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../sync/presentation/bloc/sync_bloc.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/bloc/task_state.dart';
import '../../../tasks/presentation/widgets/task_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('FIELDFlow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, taskState) {
          final tasks = taskState is TaskLoaded ? taskState.tasks : <Task>[];

          final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
          final inProgressCount = tasks.where((t) => t.status == TaskStatus.inProgress).length;
          final pendingCount = tasks.where((t) => t.status == TaskStatus.assigned || t.status == TaskStatus.accepted).length;
          final totalCount = tasks.length;
          final completionRate = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Greeting Section
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final userName = authState is Authenticated ? authState.user.name.split(' ').first : 'Technician';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, $userName 👋',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatDate(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Sync Status Banner Card
              BlocBuilder<SyncBloc, SyncState>(
                builder: (context, syncState) {
                  final hasUnsynced = syncState.hasPendingOrFailed;
                  final statusText = hasUnsynced
                      ? '${syncState.pending.length} pending • ${syncState.failed.length} failed • ${syncState.conflicts.length} conflicts'
                      : 'All changes synced';
                  final color = hasUnsynced ? AppColors.amber : AppColors.success;
                  final icon = hasUnsynced ? Icons.cloud_upload_outlined : Icons.check_circle_outline;

                  return Card(
                    color: color.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(icon, color: color, size: 22),
                      title: Text(
                        'Sync Status',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                      subtitle: Text(
                        statusText,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => context.push('/sync-center'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // KPI Progress & Statistics Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S PROGRESS",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Circular Completion Ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: CircularProgressIndicator(
                                  value: totalCount > 0 ? (completedCount / totalCount) : 0,
                                  strokeWidth: 8,
                                  backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE2E8F0),
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                '$completionRate%',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),

                          // Count Breakdowns
                          Expanded(
                            child: Column(
                              children: [
                                _buildMetricRow('Completed', completedCount, AppColors.success),
                                const SizedBox(height: 6),
                                _buildMetricRow('In Progress', inProgressCount, AppColors.warning),
                                const SizedBox(height: 6),
                                _buildMetricRow('Pending', pendingCount, AppColors.accent),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Action Shortcuts
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/tasks'),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text('All Tasks'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/ai-assistant'),
                      icon: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.amber),
                      label: const Text('AI Diagnostic'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Active Tasks Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Priority Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/tasks'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Priority Tasks List (Top 3)
              ...tasks.take(3).map(
                    (task) => TaskCard(
                      task: task,
                      onTap: () => context.push('/tasks/${task.id}'),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
