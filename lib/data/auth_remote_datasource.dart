import 'package:academic_project/domain/app_user.dart';
import 'package:dio/dio.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class AuthRemoteDataSource {
  
  final Dio _supabaseDio = Dio(BaseOptions(
    baseUrl: AppConfig.supabaseUrl,
    headers: {
      'apikey': AppConfig.supabaseKey,
      'Content-Type': 'application/json',
    },
  ));

  Future<AppUser> signup(String username, String email, String password) async {
    // Sign up on Supabase directly
    final supabaseResponse = await _supabaseDio.post(
      '/auth/v1/signup',
      data: {
        'email': email.trim(),
        'password': password,
        'data': {'username': username.trim()},
      },
    );

    return _mapSupabaseUser(supabaseResponse.data);
  }

  Future<AppUser> login(String username, String password) async {
    // username represents the user's email for Supabase login
    final response = await _supabaseDio.post(
      '/auth/v1/token?grant_type=password',
      data: {
        'email': username.trim(),
        'password': password,
      },
    );
    return _mapSupabaseUser(response.data);
  }

  AppUser _mapSupabaseUser(Map<String, dynamic> data) {
    final token = data['access_token'];
    final user = data['user'] ?? {};
    final email = user['email'] ?? '';
    final metadata = user['user_metadata'] ?? {};
    final username = metadata['username'] ?? email.split('@').first;
    return AppUser(username: username, email: email, token: token);
  }
}
