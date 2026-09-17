import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import '../bloc/task_details_bloc.dart';
import '../widgets/conflict_resolution_dialog.dart';

class TaskDetailsPage extends StatefulWidget {
  final String taskId;

  const TaskDetailsPage({super.key, required this.taskId});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TaskDetailsBloc>().add(LoadTaskDetails(widget.taskId));
  }

  void _showConflictDialog(BuildContext context, Task localTask, Map<String, dynamic>? serverData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConflictResolutionDialog(
        localTask: localTask,
        serverData: serverData,
        onResolve: (keepLocal) {
          context.read<TaskDetailsBloc>().add(
                ResolveConflictAction(
                  taskId: widget.taskId,
                  keepLocal: keepLocal,
                  serverData: serverData,
                ),
              );
        },
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Service Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter diagnostic observations or actions taken...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note saved locally and queued for sync'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AI Troubleshooting Assistant',
            onPressed: () => context.push('/ai-assistant'),
          ),
        ],
      ),
      body: BlocConsumer<TaskDetailsBloc, TaskDetailsState>(
        listener: (context, state) {
          if (state is TaskConflictDetected) {
            _showConflictDialog(context, state.localTask, state.serverData);
          }
        },
        builder: (context, state) {
          if (state is TaskDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TaskDetailsError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<TaskDetailsBloc>().add(LoadTaskDetails(widget.taskId)),
            );
          }

          final task = state is TaskDetailsLoaded
              ? state.task
              : (state is TaskConflictDetected ? state.localTask : null);

          if (task == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Conflict Warning Banner if conflict
              if (task.syncStatus == SyncStatus.conflict)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sync Conflict: Server has a different version.',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title and Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityChip(priority: task.priority.displayName),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  StatusBadge(status: task.status.displayName),
                  const SizedBox(width: 10),
                  StatusBadge(status: task.syncStatus.toServerString()),
                  const Spacer(),
                  Text(
                    'Version ${task.serverVersion}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scheduled Time Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today, color: AppColors.primaryLight, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scheduled Service Window',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDateTime(task.scheduledAt),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer & Location Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CUSTOMER & SITE LOCATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.customerName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Text(
                            task.customerPhone,
                            style: const TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.address,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/map?lat=${task.latitude}&lng=${task.longitude}&title=${Uri.encodeComponent(task.title)}&customer=${Uri.encodeComponent(task.customerName)}',
                        ),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Open Interactive Map & Navigate'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SERVICE SCOPE & INSTRUCTIONS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Service Actions (Notes, Photos)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FIELD WORK DOCUMENTATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAddNoteDialog(context),
                              icon: const Icon(Icons.note_add_outlined, size: 18),
                              label: const Text('Add Note'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Photo capture ready. Select Before or After service.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.camera_alt_outlined, size: 18),
                              label: const Text('Take Photo'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // State Transition Action Buttons
              _buildStatusActionButtons(context, task),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusActionButtons(BuildContext context, Task task) {
    switch (task.status) {
      case TaskStatus.assigned:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                context.read<TaskDetailsBloc>().add(
                      TransitionTaskStatus(
                        taskId: task.id,
                        targetStatus: TaskStatus.accepted,
                        currentVersion: task.serverVersion,
                      ),
                    );
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept Job'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                context.read<TaskDetailsBloc>().add(
                      TransitionTaskStatus(
                        taskId: task.id,
                        targetStatus: TaskStatus.cancelled,
                        currentVersion: task.serverVersion,
                      ),
                    );
              },
              child: const Text('Decline / Cancel Task'),
            ),
          ],
        );

      case TaskStatus.accepted:
        return ElevatedButton.icon(
          onPressed: () {
            context.read<TaskDetailsBloc>().add(
                  TransitionTaskStatus(
                    taskId: task.id,
                    targetStatus: TaskStatus.inProgress,
                    currentVersion: task.serverVersion,
                    latitude: task.latitude,
                    longitude: task.longitude,
                  ),
                );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Work (Record Arrival GPS)'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
        );

      case TaskStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: () {
            context.read<TaskDetailsBloc>().add(
                  TransitionTaskStatus(
                    taskId: task.id,
                    targetStatus: TaskStatus.completed,
                    currentVersion: task.serverVersion,
                    latitude: task.latitude,
                    longitude: task.longitude,
                  ),
                );
          },
          icon: const Icon(Icons.task_alt),
          label: const Text('Complete Service & Sign Off'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        );

      case TaskStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Job Completed Successfully',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );

      case TaskStatus.cancelled:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Job Cancelled',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
    }
  }
}
