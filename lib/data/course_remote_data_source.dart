import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/course.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class CourseRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/courses'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Course>> fetchCourses() async {
    final response = await _dio.get('', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Course.fromJson(e)).toList();
  }

  Future<Course> createCourse(Course course) async {
    final response = await _dio.post(
      '',
      data: course.toJson()..remove('id'),
      options: await _getOptions(),
    );
    return Course.fromJson(response.data);
  }

  Future<Course> updateCourse(Course course) async {
    final response = await _dio.put(
      '/${course.id}',
      data: course.toJson(),
      options: await _getOptions(),
    );
    return Course.fromJson(response.data);
  }

  Future<void> deleteCourse(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }
}
