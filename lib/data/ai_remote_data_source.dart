import 'package:academic_project/domain/ai_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class AiRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/ai'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<AiResponse> askAi(String prompt, {String? style, String? language, String? format}) async {
    final response = await _dio.post(
      '/ask',
      data: {
        'prompt': prompt,
        'style': style,
        'language': language,
        'format': format,
      },
      options: await _getOptions(),
    );
    return AiResponse.fromJson(response.data);
  }

  Future<List<dynamic>> getHistory() async {
    final response = await _dio.get('/history', options: await _getOptions());
    return response.data as List;
  }

  Future<void> clearHistory() async {
    await _dio.delete('/history', options: await _getOptions());
  }
}
