import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (priority.toUpperCase()) {
      case 'URGENT':
        color = AppColors.priorityUrgent;
        icon = Icons.error_rounded;
        label = 'Urgent';
        break;
      case 'HIGH':
        color = AppColors.priorityHigh;
        icon = Icons.warning_rounded;
        label = 'High';
        break;
      case 'MEDIUM':
        color = AppColors.priorityMedium;
        icon = Icons.info_rounded;
        label = 'Medium';
        break;
      case 'LOW':
      default:
        color = AppColors.priorityLow;
        icon = Icons.circle_outlined;
        label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
