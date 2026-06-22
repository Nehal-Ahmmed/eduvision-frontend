import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/settings_remote_datasource.dart';

final settingsDataSourceProvider = Provider((ref) => SettingsRemoteDataSource());

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettingsModel>>((ref) {
  return SettingsNotifier(ref.watch(settingsDataSourceProvider));
});

class SettingsNotifier extends StateNotifier<AsyncValue<UserSettingsModel>> {
  final SettingsRemoteDataSource _dataSource;

  SettingsNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _dataSource.fetchSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTheme(String theme) async {
    final currentData = state.value;
    if (currentData == null) return;
    final updated = currentData.copyWith(theme: theme);
    state = AsyncValue.data(updated);
    try {
      await _dataSource.updateSettings(updated);
    } catch (e) {
      // Revert or log
    }
  }

  Future<void> updateLanguage(String language) async {
    final currentData = state.value;
    if (currentData == null) return;
    final updated = currentData.copyWith(language: language);
    state = AsyncValue.data(updated);
    try {
      await _dataSource.updateSettings(updated);
    } catch (e) {
      // Revert or log
    }
  }

  Future<void> toggleEmailNotifications(bool enabled) async {
    final currentData = state.value;
    if (currentData == null) return;
    final updated = currentData.copyWith(emailNotifications: enabled);
    state = AsyncValue.data(updated);
    try {
      await _dataSource.updateSettings(updated);
    } catch (e) {
      // Revert or log
    }
  }

  Future<void> togglePushNotifications(bool enabled) async {
    final currentData = state.value;
    if (currentData == null) return;
    final updated = currentData.copyWith(pushNotifications: enabled);
    state = AsyncValue.data(updated);
    try {
      await _dataSource.updateSettings(updated);
    } catch (e) {
      // Revert or log
    }
  }
}
