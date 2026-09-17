import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../bloc/sync_bloc.dart';
import '../widgets/sync_operation_tile.dart';

class SyncCenterPage extends StatelessWidget {
  const SyncCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Center'),
        actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              return IconButton(
                icon: state.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Sync Now',
                onPressed: state.isSyncing
                    ? null
                    : () => context.read<SyncBloc>().add(TriggerManualSync()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          if (state.operations.isEmpty) {
            return EmptyStateView(
              title: 'Sync Queue Clean',
              message: 'All local field operations are synchronized with the central server.',
              icon: Icons.cloud_done_outlined,
              actionLabel: 'Check For Updates',
              onAction: () => context.read<SyncBloc>().add(TriggerManualSync()),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Metrics Summary Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Synced',
                      state.synced.length.toString(),
                      AppColors.success,
                      Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Pending',
                      state.pending.length.toString(),
                      AppColors.amber,
                      Icons.sync,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Failed',
                      state.failed.length.toString(),
                      AppColors.error,
                      Icons.error_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Conflict',
                      state.conflicts.length.toString(),
                      const Color(0xFFDC2626),
                      Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Toolbar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.isSyncing
                          ? null
                          : () => context.read<SyncBloc>().add(TriggerManualSync()),
                      icon: const Icon(Icons.sync, size: 18),
                      label: Text(state.isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                  if (state.failed.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isSyncing
                            ? null
                            : () => context.read<SyncBloc>().add(RetryFailedSync()),
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Retry Failed'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Section: Conflicts
              if (state.conflicts.isNotEmpty) ...[
                const Text(
                  'CONFLICTS REQUIRING ATTENTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.conflicts.map(
                  (op) => SyncOperationTile(
                    operation: op,
                    onResolve: () {
                      if (op.entityType == EntityTypeDb.task) {
                        // Navigate to task details to trigger conflict dialog
                        context.push('/tasks/${op.entityId}');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Section: Pending
              if (state.pending.isNotEmpty) ...[
                const Text(
                  'PENDING OFFLINE QUEUE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                ...state.pending.map((op) => SyncOperationTile(operation: op)),
                const SizedBox(height: 20),
              ],

              // Section: Failed
              if (state.failed.isNotEmpty) ...[
                const Text(
                  'FAILED RETRIES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.error),
                ),
                const SizedBox(height: 8),
                ...state.failed.map((op) => SyncOperationTile(operation: op)),
                const SizedBox(height: 20),
              ],

              // Section: Synced History
              if (state.synced.isNotEmpty) ...[
                const Text(
                  'RECENTLY SYNCHRONIZED',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                ...state.synced.take(15).map((op) => SyncOperationTile(operation: op)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String label, String count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
