import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_models.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileDto>>((ref) {
  return ProfileNotifier(ref.watch(profileServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileDto>> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(ProfileDto updatedProfile) async {
    try {
      final newProfile = await _service.updateProfile(updatedProfile);
      state = AsyncValue.data(newProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadProfileImage(List<int> bytes, String fileName) async {
    try {
      print('ED_Profile : (provider) -> Uploading image: $fileName, size: ${bytes.length} bytes');
      final imageUrl = await _service.uploadProfileImage(bytes, fileName);
      print('ED_Profile : (provider) -> Image uploaded successfully. URL: $imageUrl');
      
      if (state is AsyncData) {
        final currentProfile = state.value!;
        final updatedProfile = currentProfile.copyWith(profileImageUrl: imageUrl);
        print('ED_Profile : (provider) -> Updating profile with new image URL...');
        await updateProfile(updatedProfile);
        print('ED_Profile : (provider) -> Profile updated successfully with image URL.');
      }
    } catch (e, st) {
      print('ED_Profile : (provider) -> Error in uploadProfileImage: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadTranscriptPdf(List<int> bytes, String fileName) async {
    try {
      final pdfUrl = await _service.uploadTranscriptPdf(bytes, fileName);
      if (state is AsyncData) {
        final currentProfile = state.value!;
        final updatedProfile = currentProfile.copyWith(transcriptPdfUrl: pdfUrl);
        await updateProfile(updatedProfile);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadCertificateImage(int index, List<int> bytes, String fileName) async {
    try {
      final imageUrl = await _service.uploadCertificateImage(bytes, fileName);
      if (state is AsyncData) {
        final currentProfile = state.value!;
        final achievements = List<AchievementDto>.from(currentProfile.achievements);
        if (index >= 0 && index < achievements.length) {
          achievements[index] = AchievementDto(
            id: achievements[index].id,
            title: achievements[index].title,
            description: achievements[index].description,
            certificateImageUrl: imageUrl,
          );
          final updatedProfile = currentProfile.copyWith(achievements: achievements);
          await updateProfile(updatedProfile);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
