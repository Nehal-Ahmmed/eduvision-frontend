import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/note.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

class NoteRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/notes'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Note>> fetchNotes() async {
    final response = await _dio.get('/all', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Note.fromJson(e)).toList();
  }

  Future<Note> createNote(
    String content,
    String subject,
    String topic, {
    bool isFolder = false,
    int? parentId,
    String tags = '',
  }) async {
    final response = await _dio.post(
      '',
      data: {
        'content': content,
        'subject': subject,
        'topic': topic,
        'isFolder': isFolder,
        'parentId': parentId,
        'tags': tags,
      },
      options: await _getOptions(),
    );
    return Note.fromJson(response.data);
  }

  Future<Note> createFolder(String name, {int? parentId}) async {
    return createNote(
      '',
      'Folder',
      name,
      isFolder: true,
      parentId: parentId,
    );
  }

  Future<Note> updateNote(
    int id,
    String content,
    String subject,
    String topic, {
    int? parentId,
    String tags = '',
  }) async {
    final response = await _dio.put(
      '/$id',
      data: {
        'content': content,
        'subject': subject,
        'topic': topic,
        'parentId': parentId,
        'tags': tags,
      },
      options: await _getOptions(),
    );
    return Note.fromJson(response.data);
  }

  Future<void> deleteNote(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }

  Future<Note> toggleBookmark(int id) async {
    final response = await _dio.patch(
      '/$id/bookmark',
      options: await _getOptions(),
    );
    return Note.fromJson(response.data);
  }
}
