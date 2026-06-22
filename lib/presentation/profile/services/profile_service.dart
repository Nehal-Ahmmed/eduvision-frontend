import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/profile_models.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class ProfileService {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/profile'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Options _getAuthOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<ProfileDto> getProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _dio.get('', options: _getAuthOptions(token));
    return ProfileDto.fromJson(response.data);
  }

  Future<ProfileDto> updateProfile(ProfileDto profile) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await _dio.put(
      '',
      data: profile.toJson(),
      options: _getAuthOptions(token),
    );
    return ProfileDto.fromJson(response.data);
  }

  Future<String> uploadProfileImage(List<int> bytes, String fileName) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    // Detect content-type from file extension to support all image formats
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' || 'heif' => 'image/heic',
      _ => 'application/octet-stream',
    };

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });

    final response = await _dio.post(
      '/upload-image',
      data: formData,
      options: _getAuthOptions(token),
    );

    return response.data['fileUrl'];
  }

  Future<String> uploadTranscriptPdf(List<int> bytes, String fileName) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse('application/pdf'),
      ),
    });

    final response = await _dio.post(
      '/upload-transcript',
      data: formData,
      options: _getAuthOptions(token),
    );

    return response.data['fileUrl'];
  }

  Future<String> uploadCertificateImage(List<int> bytes, String fileName) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final ext = fileName.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });

    final response = await _dio.post(
      '/upload-certificate',
      data: formData,
      options: _getAuthOptions(token),
    );

    return response.data['fileUrl'];
  }
}
