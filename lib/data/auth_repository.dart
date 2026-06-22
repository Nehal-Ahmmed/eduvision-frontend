import 'package:academic_project/data/auth_remote_datasource.dart';
import 'package:academic_project/domain/app_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource = AuthRemoteDataSource();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AppUser> login(String username, String password) async {
    final user = await _remoteDataSource.login(username, password);
    if (user.token != null) {
      await _storage.write(key: 'jwt', value: user.token);
    }
    return user;
  }

  Future<AppUser> signup(String username, String email, String password) async {
    final user = await _remoteDataSource.signup(username, email, password);
    if (user.token != null) {
      await _storage.write(key: 'jwt', value: user.token);
    }
    return user;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }
}
