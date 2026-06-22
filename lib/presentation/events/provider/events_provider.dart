import 'package:academic_project/data/event_remote_data_source.dart';
import 'package:academic_project/domain/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventDataSourceProvider = Provider((ref) => EventRemoteDataSource());

final eventsProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<List<Event>>>((ref) {
      return EventsNotifier(ref.watch(eventDataSourceProvider));
    });

class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final EventRemoteDataSource _dataSource;

  EventsNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    state = const AsyncValue.loading();
    try {
      final events = await _dataSource.fetchAllEvents();
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addEvent({
    required String title,
    String? description,
    required String eventDate,
    String? startTime,
    String? endTime,
    String? location,
    required String type,
  }) async {
    try {
      await _dataSource.createEvent(
        title: title,
        description: description,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        location: location,
        type: type,
      );
      await fetchAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editEvent(
    int id, {
    required String title,
    String? description,
    required String eventDate,
    String? startTime,
    String? endTime,
    String? location,
    required String type,
  }) async {
    try {
      await _dataSource.updateEvent(
        id,
        title: title,
        description: description,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        location: location,
        type: type,
      );
      await fetchAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeEvent(int id) async {
    try {
      await _dataSource.deleteEvent(id);
      await fetchAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
