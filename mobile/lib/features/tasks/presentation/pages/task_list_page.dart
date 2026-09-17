import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/task_card.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters(BuildContext context, TaskLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(
        currentStatus: state.selectedStatus,
        currentPriority: state.selectedPriority,
        onApply: (status, priority) {
          context.read<TaskBloc>().add(FilterByStatus(status));
          context.read<TaskBloc>().add(FilterByPriority(priority));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assigned Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              final hasFilter = state is TaskLoaded &&
                  (state.selectedStatus != null || state.selectedPriority != null);

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: state is TaskLoaded ? () => _openFilters(context, state) : null,
                  ),
                  if (hasFilter)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Center',
            onPressed: () => context.push('/sync-center'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => context.read<TaskBloc>().add(SearchTasks(val)),
              decoration: InputDecoration(
                hintText: 'Search tasks, customers, or locations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TaskBloc>().add(const SearchTasks(''));
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
            ),
          ),

          // Main List View
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: 5,
                    itemBuilder: (_, __) => const TaskCardSkeleton(),
                  );
                }

                if (state is TaskError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context.read<TaskBloc>().add(RefreshTasks()),
                  );
                }

                if (state is TaskLoaded) {
                  final tasks = state.filteredTasks;

                  if (tasks.isEmpty) {
                    final isFiltered = state.selectedStatus != null ||
                        state.selectedPriority != null ||
                        state.searchQuery.isNotEmpty;

                    return EmptyStateView(
                      title: isFiltered ? 'No matching tasks' : 'No tasks assigned',
                      message: isFiltered
                          ? 'Try resetting your search or filter options.'
                          : "You're all caught up! New assigned jobs will appear here.",
                      actionLabel: isFiltered ? 'Clear Filters' : 'Refresh',
                      onAction: () {
                        if (isFiltered) {
                          _searchController.clear();
                          context.read<TaskBloc>().add(const SearchTasks(''));
                          context.read<TaskBloc>().add(const FilterByStatus(null));
                          context.read<TaskBloc>().add(const FilterByPriority(null));
                        } else {
                          context.read<TaskBloc>().add(RefreshTasks());
                        }
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TaskBloc>().add(RefreshTasks());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => context.push('/tasks/${task.id}'),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
