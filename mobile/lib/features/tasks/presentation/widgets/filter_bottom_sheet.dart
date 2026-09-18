import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task_status.dart';

class FilterBottomSheet extends StatefulWidget {
  final TaskStatus? currentStatus;
  final Priority? currentPriority;
  final Function(TaskStatus? status, Priority? priority) onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentStatus,
    required this.currentPriority,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  TaskStatus? _selectedStatus;
  Priority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedPriority = widget.currentPriority;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedPriority = null;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter
          const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              return ChoiceChip(
                label: Text(status.displayName),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.15),
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Priority Filter
          const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Priority.values.map((priority) {
              final isSelected = _selectedPriority == priority;
              return ChoiceChip(
                label: Text(priority.displayName),
                selected: isSelected,
                selectedColor: AppColors.accent.withOpacity(0.15),
                onSelected: (selected) {
                  setState(() {
                    _selectedPriority = selected ? priority : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_selectedStatus, _selectedPriority);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}

