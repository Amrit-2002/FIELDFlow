import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/troubleshooting_advice.dart';

class DiagnosticCard extends StatelessWidget {
  final TroubleshootingAdvice advice;

  const DiagnosticCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with User Query and Source Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${advice.query}"',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatDateTime(advice.timestamp),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    advice.source,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Section: Possible Causes
            Row(
              children: const [
                Icon(Icons.search, size: 18, color: AppColors.accent),
                SizedBox(width: 8),
                Text(
                  'Possible Causes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...advice.possibleCauses.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final cause = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$index. ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
                    Expanded(child: Text(cause, style: const TextStyle(fontSize: 13, height: 1.3))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Section: Recommended Checks
            Row(
              children: const [
                Icon(Icons.checklist, size: 18, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Recommended Checks',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...advice.recommendedChecks.asMap().entries.map((entry) {
              final check = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outlined, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(check, style: const TextStyle(fontSize: 13, height: 1.3))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Section: Safety Notes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.security, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safety Notes',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advice.safetyNotes,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: isDark ? Colors.grey[200] : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Disclaimer Footer
            const Center(
              child: Text(
                'AI Assistant provides advisory guidance. Always follow site-specific safety protocols.',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

