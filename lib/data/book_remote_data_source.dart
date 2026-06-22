import 'package:academic_project/domain/book.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';

/// Remote data source for Book API calls.
/// Follows the same pattern as NoteRemoteDataSource.
class BookRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/api/books'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // =========================================
  // Fetch all books (full list)
  // =========================================

  Future<List<Book>> fetchBooks() async {
    final response = await _dio.get('/all', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Book.fromJson(e)).toList();
  }

  // =========================================
  // Upload a new book (multipart file + metadata)
  // =========================================

  Future<Book> uploadBook({
    required List<int> fileBytes,
    required String fileName,
    required String title,
    String? author,
    String? description,
    String? isbn,
    String? language,
    String? category,
    int? numberOfPages,
  }) async {
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
        if (author != null) 'author': author,
        if (description != null) 'description': description,
        if (isbn != null) 'isbn': isbn,
        if (language != null) 'language': language,
        if (category != null) 'category': category,
        if (numberOfPages != null) 'numberOfPages': numberOfPages,
      },
      options: options,
    );
    return Book.fromJson(response.data);
  }

  // =========================================
  // Get single book by ID
  // =========================================

  Future<Book> getBookById(int id) async {
    final response = await _dio.get('/$id', options: await _getOptions());
    return Book.fromJson(response.data);
  }

  // =========================================
  // Update book metadata
  // =========================================

  Future<Book> updateBook(
    int id, {
    required String title,
    String? author,
    String? description,
    String? isbn,
    String? language,
    String? category,
    int? numberOfPages,
  }) async {
    final response = await _dio.put(
      '/$id',
      data: {
        'title': title,
        'author': author,
        'description': description,
        'isbn': isbn,
        'language': language,
        'category': category,
        'numberOfPages': numberOfPages,
      },
      options: await _getOptions(),
    );
    return Book.fromJson(response.data);
  }

  // =========================================
  // Delete book
  // =========================================

  Future<void> deleteBook(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }

  // =========================================
  // Toggle favorite
  // =========================================

  Future<Book> toggleFavorite(int id) async {
    final response = await _dio.patch(
      '/$id/favorite',
      options: await _getOptions(),
    );
    return Book.fromJson(response.data);
  }

  // =========================================
  // Search books (multi-field)
  // =========================================

  Future<List<Book>> searchBooks({
    String? query,
    String? category,
    String? author,
    String? language,
  }) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null && category.isNotEmpty) 'category': category,
        if (author != null && author.isNotEmpty) 'author': author,
        if (language != null && language.isNotEmpty) 'language': language,
      },
      options: await _getOptions(),
    );
    final List data = response.data;
    return data.map((e) => Book.fromJson(e)).toList();
  }

  // =========================================
  // Get book count
  // =========================================

  Future<int> getBookCount() async {
    final response = await _dio.get('/count', options: await _getOptions());
    return response.data['count'];
  }

  // =========================================
  // Get distinct filter values (for sidebar dropdowns)
  // =========================================

  Future<List<String>> getCategories() async {
    final response = await _dio.get('/filters/categories', options: await _getOptions());
    return List<String>.from(response.data);
  }

  Future<List<String>> getAuthors() async {
    final response = await _dio.get('/filters/authors', options: await _getOptions());
    return List<String>.from(response.data);
  }

  Future<List<String>> getLanguages() async {
    final response = await _dio.get('/filters/languages', options: await _getOptions());
    return List<String>.from(response.data);
  }

  // =========================================
  // Book file download URL (for reading/opening)
  // =========================================

  Future<String> getBookFileUrl(int bookId) async {
    final token = await _storage.read(key: 'jwt');
    final url = '${AppConfig.apiBaseUrl}/api/books/files/$bookId?token=$token';
    print('[book download] getBookFileUrl generated: $url (token length: ${token?.length ?? 0})');
    return url;
  }
}
