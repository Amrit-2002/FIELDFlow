import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum NetworkStatus { online, offline, syncing }

class NetworkStatusBar extends StatelessWidget {
  final NetworkStatus status;
  final String? customMessage;

  const NetworkStatusBar({
    super.key,
    required this.status,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    String text;

    switch (status) {
      case NetworkStatus.online:
        bg = AppColors.success;
        icon = Icons.check_circle_outline;
        text = customMessage ?? 'All changes synced';
        break;
      case NetworkStatus.offline:
        bg = const Color(0xFF475569);
        icon = Icons.cloud_off_outlined;
        text = customMessage ?? 'Offline mode — local changes will sync';
        break;
      case NetworkStatus.syncing:
        bg = AppColors.accent;
        icon = Icons.sync;
        text = customMessage ?? 'Back online — syncing changes...';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

