import 'package:flutter/material.dart';
import 'app.dart';
import 'features/notifications/data/datasources/notification_service.dart';
import 'injection/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
