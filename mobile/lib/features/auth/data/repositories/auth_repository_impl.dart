import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<User> login({required String email, required String password}) async {
    final result = await _remoteDataSource.login(email: email, password: password);

    final accessToken = result['accessToken'] as String;
    final refreshToken = result['refreshToken'] as String;
    final userModel = UserModel.fromJson(result['user'] as Map<String, dynamic>);

    await _localDataSource.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: userModel,
    );

    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _localDataSource.clearSession();
  }

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await _localDataSource.getCachedUser();
    return userModel?.toEntity();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _localDataSource.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
