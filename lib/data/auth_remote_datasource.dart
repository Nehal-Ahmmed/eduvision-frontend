import 'package:academic_project/domain/app_user.dart';
import 'package:dio/dio.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class AuthRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/auth'));

  Future<AppUser> signup(String username, String email, String password) async {
    final response = await _dio.post(
      '/signup',
      data: {'username': username, 'email': email, 'password': password},
    );
    return AppUser.fromJson(response.data);
  }

  Future<AppUser> login(String username, String password) async {
    final response = await _dio.post(
      '/login',
      data: {'username': username, 'password': password},
    );
    return AppUser.fromJson(response.data);
  }
}
