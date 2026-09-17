import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, super.code, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Device is currently offline', super.code = 'NETWORK_OFFLINE'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code = 'AUTH_ERROR'});
}

class ConflictFailure extends Failure {
  final Map<String, dynamic>? serverData;
  final int? serverVersion;
  final int? localVersion;

  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
    this.serverData,
    this.serverVersion,
    this.localVersion,
  });

  @override
  List<Object?> get props => [message, code, serverData, serverVersion, localVersion];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code = 'DB_ERROR'});
}

class SyncFailure extends Failure {
  const SyncFailure({required super.message, super.code = 'SYNC_ERROR'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'VALIDATION_ERROR'});
}
