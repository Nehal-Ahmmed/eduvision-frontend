import 'package:academic_project/data/ai_remote_data_source.dart';
import 'package:academic_project/domain/ai_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(AiRemoteDataSource());
});

class AiState {
  final bool isLoading;
  final AiResponse? response;
  final String? error;
  final String selectedStyle;
  final String selectedLanguage;
  final String selectedFormat;

  AiState({
    this.isLoading = false, 
    this.response, 
    this.error,
    this.selectedStyle = 'Academic',
    this.selectedLanguage = 'English',
    this.selectedFormat = 'None',
  });

  AiState copyWith({
    bool? isLoading, 
    AiResponse? response, 
    String? error,
    String? selectedStyle,
    String? selectedLanguage,
    String? selectedFormat,
  }) {
    return AiState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error ?? this.error,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedFormat: selectedFormat ?? this.selectedFormat,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  final AiRemoteDataSource _dataSource;
  AiNotifier(this._dataSource) : super(AiState());

  void setStyle(String style) {
    state = state.copyWith(selectedStyle: style);
  }

  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  void setFormat(String format) {
    state = state.copyWith(selectedFormat: format);
  }

  Future<void> askAi(String prompt) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final aiResponse = await _dataSource.askAi(
        prompt, 
        style: state.selectedStyle, 
        language: state.selectedLanguage,
        format: state.selectedFormat == 'None' ? null : state.selectedFormat,
      );
      state = state.copyWith(isLoading: false, response: aiResponse);
    } catch (e) {
      String errorMessage = "Failed to get AI response. Please try again.";
      if (e is Exception) {
        errorMessage = e.toString();
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  void clearResponse() {
    state = AiState();
  }
}
