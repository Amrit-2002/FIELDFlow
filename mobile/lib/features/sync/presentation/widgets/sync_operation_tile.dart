import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../../../core/utils/date_formatter.dart';

class SyncOperationTile extends StatelessWidget {
  final SyncOperationsTableData operation;
  final VoidCallback? onResolve;

  const SyncOperationTile({
    super.key,
    required this.operation,
    this.onResolve,
  });

  String _getEntityTitle() {
    final typeName = operation.entityType.name[0].toUpperCase() + operation.entityType.name.substring(1);
    final shortId = operation.entityId.length > 8
        ? operation.entityId.substring(0, 8)
        : operation.entityId;

    try {
      final payload = jsonDecode(operation.payload) as Map<String, dynamic>;
      if (payload['status'] != null) {
        return '$typeName #$shortId • Status: ${payload['status']}';
      }
      if (payload['content'] != null) {
        return '$typeName #$shortId • "${payload['content']}"';
      }
    } catch (_) {}

    return '$typeName #$shortId';
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    String statusLabel;

    switch (operation.status) {
      case SyncStatusDb.synced:
        iconColor = AppColors.success;
        icon = Icons.check_circle_outline;
        statusLabel = 'Synced';
        break;
      case SyncStatusDb.pending:
        iconColor = AppColors.amber;
        icon = Icons.sync;
        statusLabel = 'Pending';
        break;
      case SyncStatusDb.failed:
        iconColor = AppColors.error;
        icon = Icons.error_outline;
        statusLabel = 'Failed (${operation.retryCount} retries)';
        break;
      case SyncStatusDb.conflict:
        iconColor = AppColors.error;
        icon = Icons.warning_amber_rounded;
        statusLabel = 'Version Conflict (409)';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          _getEntityTitle(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Queued ${DateFormatter.formatRelative(operation.createdAt)} • $statusLabel',
              style: TextStyle(fontSize: 12, color: iconColor),
            ),
            if (operation.lastError != null && operation.lastError!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                operation.lastError!,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: operation.status == SyncStatusDb.conflict && onResolve != null
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(70, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onResolve,
                child: const Text('Resolve', style: TextStyle(fontSize: 12)),
              )
            : null,
      ),
    );
  }
}
