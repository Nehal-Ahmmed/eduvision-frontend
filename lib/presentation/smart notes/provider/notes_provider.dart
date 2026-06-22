import 'package:academic_project/data/note_remote_data_source.dart';
import 'package:academic_project/domain/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final noteDataSourceProvider = Provider((ref) => NoteRemoteDataSource());

final notesProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
      return NotesNotifier(ref.watch(noteDataSourceProvider));
    });

final activeNoteIdProvider = StateProvider<int?>((ref) => null);

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRemoteDataSource _dataSource;

  NotesNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _dataSource.fetchNotes();
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNote(
    String content,
    String subject,
    String topic, {
    int? parentId,
    String tags = '',
  }) async {
    try {
      await _dataSource.createNote(content, subject, topic, parentId: parentId, tags: tags);
      await fetchNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createFolder(String name, {int? parentId}) async {
    try {
      await _dataSource.createFolder(name, parentId: parentId);
      await fetchNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateNote(
    int id,
    String content,
    String subject,
    String topic, {
    int? parentId,
    String tags = '',
  }) async {
    try {
      await _dataSource.updateNote(id, content, subject, topic, parentId: parentId, tags: tags);
      await fetchNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dataSource.deleteNote(id);
      await fetchNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleBookmark(int id) async {
    try {
      await _dataSource.toggleBookmark(id);
      await fetchNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
