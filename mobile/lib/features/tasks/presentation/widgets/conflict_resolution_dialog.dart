import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final Task localTask;
  final Map<String, dynamic>? serverData;
  final Function(bool keepLocal) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.localTask,
    this.serverData,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final serverStatus = serverData?['status'] ?? 'UPDATED ON SERVER';
    final serverVersion = serverData?['version'] ?? (localTask.serverVersion + 1);

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Version Conflict Detected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This task was modified on the server or dispatch center while you were working offline.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Comparison Table
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Your Local Version',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Server Version',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Status: ${localTask.status.displayName}\nv${localTask.serverVersion}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Status: $serverStatus\nv$serverVersion',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How would you like to resolve this conflict?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onResolve(false); // Accept server version
          },
          child: const Text('Accept Server Version'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(110, 40),
          ),
          onPressed: () {
            Navigator.pop(context);
            onResolve(true); // Keep local changes and override
          },
          child: const Text('Keep My Changes'),
        ),
      ],
    );
  }
}

