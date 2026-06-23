import 'dart:convert';
import 'package:academic_project/data/auth_repository.dart';
import 'package:academic_project/domain/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final token = await _repository.getToken();
      if (token != null) {
        final user = _parseUserFromToken(token);
        if (user != null) {
          state = AsyncValue.data(user);
          return;
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  AppUser? _parseUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      
      final String normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = json.decode(decoded);
      
      final email = claims['email'] ?? '';
      final metadata = claims['user_metadata'] ?? {};
      final username = metadata['username'] ?? email.split('@').first;
      
      return AppUser(username: username, email: email, token: token);
    } catch (e) {
      print('Error parsing JWT on startup: $e');
      return null;
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(username, password);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print(e);
    }
  }

  Future<void> signup(String username, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signup(username, email, password);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print(e);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
