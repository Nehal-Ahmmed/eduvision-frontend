import 'package:academic_project/domain/event.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class EventRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/events'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Event>> fetchAllEvents() async {
    final response = await _dio.get('', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Event.fromJson(e)).toList();
  }

  Future<List<Event>> fetchUpcomingEvents() async {
    final response = await _dio.get('/upcoming', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Event.fromJson(e)).toList();
  }

  Future<List<Event>> fetchTodayEvents() async {
    final response = await _dio.get('/today', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Event.fromJson(e)).toList();
  }

  Future<List<Event>> fetchPastEvents() async {
    final response = await _dio.get('/past', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> createEvent({
    required String title,
    String? description,
    required String eventDate,
    String? startTime,
    String? endTime,
    String? location,
    required String type,
  }) async {
    final response = await _dio.post(
      '',
      data: {
        'title': title,
        'description': description,
        'eventDate': eventDate,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'type': type,
      },
      options: await _getOptions(),
    );
    return Event.fromJson(response.data);
  }

  Future<Event> updateEvent(
    int id, {
    required String title,
    String? description,
    required String eventDate,
    String? startTime,
    String? endTime,
    String? location,
    required String type,
  }) async {
    final response = await _dio.put(
      '/$id',
      data: {
        'title': title,
        'description': description,
        'eventDate': eventDate,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'type': type,
      },
      options: await _getOptions(),
    );
    return Event.fromJson(response.data);
  }

  Future<void> deleteEvent(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }
}
