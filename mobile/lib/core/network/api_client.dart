import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({
    required SecureStorageService storage,
    Dio? customDio,
    void Function()? onSessionExpired,
  }) {
    dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        dio: dio,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters, options: options);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post(path, data: data, queryParameters: queryParameters, options: options);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.patch(path, data: data, queryParameters: queryParameters, options: options);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.delete(path, data: data, queryParameters: queryParameters, options: options);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      if (body['success'] == true) {
        return body['data'];
      }
      throw ServerException(
        message: body['error']?['message'] ?? 'An unexpected error occurred',
        code: body['error']?['code'],
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException(message: 'Connection timed out or network unavailable');
    }

    final response = e.response;
    if (response != null) {
      final status = response.statusCode;
      final data = response.data;

      // Check HTTP 409 Conflict (Optimistic Concurrency)
      if (status == 409) {
        final errorObj = data is Map ? data['error'] : null;
        return ConflictException(
          message: errorObj?['message'] ?? 'Conflict detected: Task was modified on server',
          serverData: errorObj?['details']?['serverTask'],
          expectedVersion: errorObj?['details']?['expectedVersion'],
          currentVersion: errorObj?['details']?['currentVersion'],
        );
      }

      if (status == 401) {
        return const UnauthorizedException();
      }

      if (data is Map && data['error'] != null) {
        return ServerException(
          message: data['error']['message'] ?? 'Server error',
          code: data['error']['code'],
          statusCode: status,
        );
      }

      return ServerException(
        message: response.statusMessage ?? 'Server returned status $status',
        statusCode: status,
      );
    }

    return NetworkException(message: e.message ?? 'Network error occurred');
  }
}
