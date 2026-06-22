import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class UserSettingsModel {
  final String theme;
  final String language;
  final bool emailNotifications;
  final bool pushNotifications;

  UserSettingsModel({
    required this.theme,
    required this.language,
    required this.emailNotifications,
    required this.pushNotifications,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      theme: json['theme'] ?? 'light',
      language: json['language'] ?? 'en',
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  UserSettingsModel copyWith({
    String? theme,
    String? language,
    bool? emailNotifications,
    bool? pushNotifications,
  }) {
    return UserSettingsModel(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}

class SettingsRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/settings'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<UserSettingsModel> fetchSettings() async {
    try {
      final response = await _dio.get('', options: await _getOptions());
      return UserSettingsModel.fromJson(response.data);
    } catch (e) {
      // Return default if error
      return UserSettingsModel(
        theme: 'light',
        language: 'en',
        emailNotifications: true,
        pushNotifications: true,
      );
    }
  }

  Future<UserSettingsModel> updateSettings(UserSettingsModel settings) async {
    final response = await _dio.put(
      '',
      data: settings.toJson(),
      options: await _getOptions(),
    );
    return UserSettingsModel.fromJson(response.data);
  }
}
