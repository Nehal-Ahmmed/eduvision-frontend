import 'package:academic_project/domain/resource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';


class ResourceRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/resources'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Resource> addLink(String title, String? description, String url, String type, int noteId) async {
    final response = await _dio.post(
      '/link',
      queryParameters: {
        'title': title,
        'description': description,
        'url': url,
        'type': type,
        'noteId': noteId,
      },
      options: await _getOptions(),
    );
    return Resource.fromJson(response.data);
  }

  Future<Resource> uploadFile(String title, String? description, List<int> fileBytes, String fileName, String type, int noteId) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final options = await _getOptions();
    options.contentType = 'multipart/form-data';

    final response = await _dio.post(
      '/upload',
      data: formData,
      queryParameters: {
        'title': title,
        'description': description,
        'type': type,
        'noteId': noteId,
      },
      options: options,
    );
    return Resource.fromJson(response.data);
  }

  Future<List<Resource>> getResourcesByNote(int noteId) async {
    final response = await _dio.get('/note/$noteId', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Resource.fromJson(e)).toList();
  }

  Future<void> deleteResource(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }
}
