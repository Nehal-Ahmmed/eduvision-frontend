import 'package:academic_project/data/book_remote_data_source.dart';
import 'package:academic_project/domain/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the BookRemoteDataSource singleton
final bookDataSourceProvider = Provider((ref) => BookRemoteDataSource());

/// Main books list provider — StateNotifier wrapping AsyncValue<List<Book>>
/// Follows the exact same pattern as notesProvider / NotesNotifier.
final booksProvider =
    StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  return BooksNotifier(ref.watch(bookDataSourceProvider));
});

/// Currently selected/active book ID (for details view)
final activeBookIdProvider = StateProvider<int?>((ref) => null);

/// Total book count (displayed in the shelf header)
final bookCountProvider = StateProvider<int>((ref) => 0);

/// Distinct categories from the user's library (for sidebar)
final bookCategoriesProvider =
    StateNotifierProvider<FilterListNotifier, AsyncValue<List<String>>>((ref) {
  return FilterListNotifier(
    () => ref.watch(bookDataSourceProvider).getCategories(),
  );
});

/// Distinct authors from the user's library (for sidebar)
final bookAuthorsProvider =
    StateNotifierProvider<FilterListNotifier, AsyncValue<List<String>>>((ref) {
  return FilterListNotifier(
    () => ref.watch(bookDataSourceProvider).getAuthors(),
  );
});

/// Distinct languages from the user's library (for sidebar)
final bookLanguagesProvider =
    StateNotifierProvider<FilterListNotifier, AsyncValue<List<String>>>((ref) {
  return FilterListNotifier(
    () => ref.watch(bookDataSourceProvider).getLanguages(),
  );
});

// ================================================
// BooksNotifier — main state management for books
// ================================================

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRemoteDataSource _dataSource;

  BooksNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    fetchBooks();
  }

  /// Fetch all books from the backend
  Future<void> fetchBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await _dataSource.fetchBooks();
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Upload a new book (file + metadata), then refresh the list
  Future<void> uploadBook({
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
    try {
      await _dataSource.uploadBook(
        fileBytes: fileBytes,
        fileName: fileName,
        title: title,
        author: author,
        description: description,
        isbn: isbn,
        language: language,
        category: category,
        numberOfPages: numberOfPages,
      );
      await fetchBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw e;
    }
  }

  /// Delete a book by ID, then refresh the list
  Future<void> deleteBook(int id) async {
    try {
      await _dataSource.deleteBook(id);
      await fetchBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Toggle the favorite status of a book
  Future<void> toggleFavorite(int id) async {
    try {
      await _dataSource.toggleFavorite(id);
      await fetchBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Search/filter books by query, category, author, language
  Future<void> searchBooks({
    String? query,
    String? category,
    String? author,
    String? language,
  }) async {
    state = const AsyncValue.loading();
    try {
      final books = await _dataSource.searchBooks(
        query: query,
        category: category,
        author: author,
        language: language,
      );
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// ================================================
// FilterListNotifier — for distinct filter values
// ================================================

class FilterListNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Future<List<String>> Function() _fetcher;

  FilterListNotifier(this._fetcher) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final values = await _fetcher();
      state = AsyncValue.data(values);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
