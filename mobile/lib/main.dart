import 'package:flutter/material.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';
import 'features/notifications/data/datasources/notification_service.dart';
import 'injection/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve best base URL (USB adb reverse 127.0.0.1, emulator 10.0.2.2, or LAN)
  await ApiConstants.resolveBaseUrl();

  // Initialize Dependency Injection
  await initServiceLocator();

  // Initialize Local Notifications
  try {
    await sl<LocalNotificationService>().init();
  } catch (_) {
    // Non-fatal if permissions or platform plugins aren't ready on desktop/web
  }

  runApp(const FieldFlowApp());
}
