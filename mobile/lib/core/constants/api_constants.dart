import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConstants {
  static String? _overrideBaseUrl;
  static String? _overrideOllamaUrl;

  /// Fast probe to detect whether we are on a physical device with adb reverse
  /// (127.0.0.1), Android Emulator (10.0.2.2), or local LAN.
  static Future<void> resolveBaseUrl() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // 1. Probe 127.0.0.1 (Physical device over USB reverse)
        if (await _probeHost('127.0.0.1', 5000)) {
          _overrideBaseUrl = 'http://127.0.0.1:5000/api/v1';
          _overrideOllamaUrl = 'http://127.0.0.1:11434';
          return;
        }

        // 2. Probe 10.0.2.2 (Android Emulator virtual gateway)
        if (await _probeHost('10.0.2.2', 5000)) {
          _overrideBaseUrl = 'http://10.0.2.2:5000/api/v1';
          _overrideOllamaUrl = 'http://10.0.2.2:11434';
          return;
        }

        // 3. Probe LAN IP
        if (await _probeHost('10.94.127.63', 5000)) {
          _overrideBaseUrl = 'http://10.94.127.63:5000/api/v1';
          _overrideOllamaUrl = 'http://10.94.127.63:11434';
          return;
        }
      }
    } catch (_) {}
  }

  static Future<bool> _probeHost(String host, int port) async {
    try {
      final response = await http
          .get(Uri.parse('http://$host:$port/api/v1/health'))
          .timeout(const Duration(milliseconds: 600));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Configurable base URL based on runtime platform
  static String get baseUrl {
    if (_overrideBaseUrl != null) return _overrideBaseUrl!;
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }

  // Ollama local AI server base URL
  static String get ollamaBaseUrl {
    if (_overrideOllamaUrl != null) return _overrideOllamaUrl!;
    if (kIsWeb) {
      return 'http://localhost:11434';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:11434';
    }
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

