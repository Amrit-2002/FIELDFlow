import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL based on runtime platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:5000/api/v1';
  }

  // Ollama local AI server base URL
  static String get ollamaBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:11434';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:11434';
      }
    } catch (_) {}
    return 'http://localhost:11434';
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Task Endpoints
  static const String tasks = '/tasks';
  static String taskDetails(String id) => '/tasks/$id';
  static String taskStatus(String id) => '/tasks/$id/status';
  static String taskNotes(String id) => '/tasks/$id/notes';
  static String taskPhotos(String id) => '/tasks/$id/photos';
  static String taskLocations(String id) => '/tasks/$id/locations';

  // Sync Endpoint
  static const String sync = '/sync';

  // Notifications Endpoint
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  // Health
  static const String health = '/health';
}
