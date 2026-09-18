import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        bg = AppColors.statusAssigned.withOpacity(0.12);
        text = AppColors.statusAssigned;
        label = 'Assigned';
        break;
      case 'ACCEPTED':
        bg = AppColors.statusAccepted.withOpacity(0.12);
        text = AppColors.statusAccepted;
        label = 'Accepted';
        break;
      case 'IN_PROGRESS':
        bg = AppColors.statusInProgress.withOpacity(0.15);
        text = const Color(0xFFD97706);
        label = 'In Progress';
        break;
      case 'COMPLETED':
        bg = AppColors.statusCompleted.withOpacity(0.15);
        text = const Color(0xFF059669);
        label = 'Completed';
        break;
      case 'CANCELLED':
        bg = AppColors.statusCancelled.withOpacity(0.12);
        text = AppColors.statusCancelled;
        label = 'Cancelled';
        break;
      case 'SYNCED':
        bg = AppColors.success.withOpacity(0.15);
        text = const Color(0xFF059669);
        label = 'Synced';
        break;
      case 'PENDING':
        bg = AppColors.amber.withOpacity(0.15);
        text = const Color(0xFFD97706);
        label = 'Pending';
        break;
      case 'CONFLICT':
        bg = AppColors.error.withOpacity(0.15);
        text = AppColors.error;
        label = 'Conflict';
        break;
      case 'FAILED':
        bg = AppColors.error.withOpacity(0.15);
        text = AppColors.error;
        label = 'Failed';
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        text = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

