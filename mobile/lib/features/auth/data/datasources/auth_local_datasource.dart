import '../../../../core/database/app_database.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession({required String accessToken, required String refreshToken, required UserModel user});
  Future<UserModel?> getCachedUser();
  Future<String?> getAccessToken();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _secureStorage;
  final AppDatabase _db;

  AuthLocalDataSourceImpl({
    required SecureStorageService secureStorage,
    required AppDatabase db,
  })  : _secureStorage = secureStorage,
        _db = db;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _secureStorage.saveUserData(user.toJson());

    // Also persist in SQLite
    await _db.into(_db.usersTable).insertOnConflictUpdate(
          UsersTableCompanion.insert(
            id: user.id,
            name: user.name,
            email: user.email,
          ),
        );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final map = await _secureStorage.getUserData();
    if (map == null) return null;
    return UserModel.fromJson(map);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.getAccessToken();
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.clearAll();
  }
}

