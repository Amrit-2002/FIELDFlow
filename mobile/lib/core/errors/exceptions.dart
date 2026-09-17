class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (code: $code, status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'No active internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException({this.message = 'Authentication session has expired'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ConflictException implements Exception {
  final String message;
  final Map<String, dynamic>? serverData;
  final int? expectedVersion;
  final int? currentVersion;

  const ConflictException({
    required this.message,
    this.serverData,
    this.expectedVersion,
    this.currentVersion,
  });

  @override
  String toString() => 'ConflictException: $message (serverVer: $currentVersion, expectedVer: $expectedVersion)';
}

class DatabaseException implements Exception {
  final String message;
  const DatabaseException({required this.message});

  @override
  String toString() => 'DatabaseException: $message';
}

class SyncException implements Exception {
  final String message;
  final String? operationId;
  const SyncException({required this.message, this.operationId});

  @override
  String toString() => 'SyncException: $message (op: $operationId)';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException({required this.message});

  @override
  String toString() => 'ValidationException: $message';
}
