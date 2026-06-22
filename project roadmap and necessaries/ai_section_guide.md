# 🗺️ AI Section Implementation Guide

This guide provides a comprehensive breakdown of the AI-powered Academic Assistant implemented in the EduVision system.

## 1. 🗺️ High-Level Roadmap
1.  **Backend DTO Alignment**: Updated `AiResponse` to include a `topic` field for better concept tracking.
2.  **Robust AI Integration**: Enhanced `GeminiService` with a robust prompt and custom JSON extraction logic to handle various Gemini response formats.
3.  **Frontend Architecture**: Refactored Flutter code to use a dedicated `AiRemoteDataSource`, separating API logic from UI state management.
4.  **Feature Integration**: Refactored "Attach to Note" to use the centralized `ResourceRemoteDataSource`, enabling reliable PDF uploads of AI summaries.
5.  **UX Polish**: Implemented loading states, error handling, and premium animations for a smooth user experience.

## 2. 🧠 Logical Descriptions

### Backend Layer
-   **Simple**: The backend acts as a bridge between the student and Google Gemini. It takes a concept, asks Gemini for a structured breakdown (Academic, Simple, Exam-standard), and ensures the result is a clean JSON object.
-   **Technical**: `GeminiService` uses `RestTemplate` to call the Gemini 1.5 Flash API. It provides a strict system instruction to ensure JSON output and uses a robust substring extraction method (`indexOf("{")` and `lastIndexOf("}")`) to parse the JSON response safely, even if the model adds conversational fluff.

### Frontend Layer
-   **Simple**: Students type a concept into a sleek search bar. The AI provides definitions in different "flavors." Students can then copy the text, save it as a PDF locally, or attach it directly to their study notes.
-   **Technical**: The UI is built using `Riverpod` for state management (`AiProvider`). It uses `flutter_animate` for premium feel and the `pdf` package for document generation. The `AiRemoteDataSource` handles communication with the Spring Boot backend using `Dio`.

## 3. 💻 Full Implementation Code

### Backend: AiResponse.java
```java
package com.academicproject.eduvisionbackend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class AiResponse {
    private String topic;
    private String academicDefinition;
    private String simpleDefinition;
    private String examStandardDescription;
}
```

### Backend: GeminiService.java
```java
package com.academicproject.eduvisionbackend.service;

import com.academicproject.eduvisionbackend.dto.AiResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class GeminiService {

    @Value("${gemini.api.key}")
    private String apiKey;

    private final String API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=";
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AiResponse getStructuredResponse(String prompt) {
        String url = API_URL + apiKey;

        String systemPrompt = "You are an AI academic assistant for students. " +
                "For any concept provided, you must return a JSON object with exactly four fields: " +
                "\"topic\" (the name of the concept), " +
                "\"academicDefinition\" (a formal, high-level academic definition), " +
                "\"simpleDefinition\" (a definition in very simple terms for easy understanding), " +
                "\"examStandardDescription\" (a detailed explanation suitable for writing in an exam). " +
                "Respond ONLY with the JSON object. Do not include markdown formatting like ```json or any other text.";

        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> content = new HashMap<>();
        Map<String, String> part = new HashMap<>();
        part.put("text", systemPrompt + "\n\nConcept: " + prompt);
        content.put("parts", List.of(part));
        requestBody.put("contents", List.of(content));

        try {
            String responseStr = restTemplate.postForObject(url, requestBody, String.class);
            JsonNode root = objectMapper.readTree(responseStr);
            String textResponse = root.path("candidates").get(0).path("content").path("parts").get(0).path("text").asText();
            
            int start = textResponse.indexOf("{");
            int end = textResponse.lastIndexOf("}");
            if (start != -1 && end != -1 && end > start) {
                textResponse = textResponse.substring(start, end + 1);
            }
            
            return objectMapper.readValue(textResponse, AiResponse.class);
        } catch (Exception e) {
            return AiResponse.builder()
                    .topic(prompt)
                    .academicDefinition("Error retrieving definition.")
                    .simpleDefinition("Something went wrong with the AI service.")
                    .examStandardDescription("Details: " + e.getMessage())
                    .build();
        }
    }
}
```

### Frontend: ai_remote_data_source.dart
```dart
import 'package:academic_project/domain/ai_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/ai'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<AiResponse> askAi(String prompt) async {
    final response = await _dio.post(
      '/ask',
      data: {'prompt': prompt},
      options: await _getOptions(),
    );
    return AiResponse.fromJson(response.data);
  }
}
```

## 4. 🛠️ Extra Steps
1.  **API Key**: Ensure `gemini.api.key` is set in `application.properties`.
2.  **Dependencies**: Ensure `flutter_animate`, `pdf`, `printing`, and `google_fonts` are in `pubspec.yaml`.
3.  **CORS**: The `GeminiController` is configured with `@CrossOrigin(origins = "*")` to allow Flutter web/emulator requests.

## 📝 Summary
Data flows from the `AiAssistantScreen` text field → `AiProvider` → `AiRemoteDataSource` → Spring Boot `GeminiController` → `GeminiService` → Google Gemini API. The response is parsed, returned as a DTO, and displayed in premium animated cards. Students can then persist this knowledge by attaching it as a PDF resource to their notes.
