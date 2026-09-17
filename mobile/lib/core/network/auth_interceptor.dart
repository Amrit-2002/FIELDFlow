import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;
  final List<Completer<void>> _pendingRequests = [];

  AuthInterceptor({
    required SecureStorageService storage,
    required Dio dio,
    this.onSessionExpired,
  })  : _storage = storage,
        _dio = dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token injection for login or refresh requests
    if (options.path.contains(ApiConstants.login) || options.path.contains(ApiConstants.refresh)) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || err.requestOptions.path.contains(ApiConstants.login)) {
      return handler.next(err);
    }

    // Attempt token refresh
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleLogout();
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Queue subsequent 401 requests while one refresh is already in progress
      final completer = Completer<void>();
      _pendingRequests.add(completer);
      try {
        await completer.future;
        final newAccessToken = await _storage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (retryError) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      final refreshResponse = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.refresh}',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
        final data = refreshResponse.data['data'];
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Resume all queued requests
        for (final completer in _pendingRequests) {
          if (!completer.isCompleted) completer.complete();
        }
        _pendingRequests.clear();

        // Retry original request with new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } else {
        await _handleLogout();
        return handler.next(err);
      }
    } catch (refreshErr) {
      await _handleLogout();
      for (final completer in _pendingRequests) {
        if (!completer.isCompleted) completer.completeError(refreshErr);
      }
      _pendingRequests.clear();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handleLogout() async {
    await _storage.clearAll();
    onSessionExpired?.call();
  }
}
