# 🤖 AI Assistant Feature Guide

Welcome to the **AI Assistant** implementation guide. This feature integrates the Google Gemini API to provide students with structured academic definitions, simple explanations, and exam-standard descriptions.

## 🗺️ High-Level Roadmap

1.  **Backend Integration**: Created a dedicated `GeminiService` to interact with Google's Generative Language API.
2.  **Structured Prompting**: Implemented system prompts to force Gemini to return structured JSON data.
3.  **Frontend State Management**: Used Riverpod to manage AI interaction states (loading, response, error).
4.  **Student-Centric UI**: Designed a specialized UI with three distinct categories for learning.
5.  **PDF Engine**: Integrated `pdf` and `printing` packages to allow students to download and save explanations.
6.  **Resource Attachment**: Added logic to attach AI-generated PDFs directly to academic notes as persistent study resources.

## 🧠 Logical Descriptions

### Backend Layer
-   **Simple**: A bridge that takes a student's question, asks an "expert" (Gemini), and translates the answer into a specific format (JSON).
-   **Technical**: A Spring Boot `@RestController` calls a `GeminiService` which uses `RestTemplate` to send a POST request to the Google Generative Language API. It uses a specific system instruction to ensure the model output is a parseable JSON object containing `academicDefinition`, `simpleDefinition`, and `examStandardDescription`.

### Frontend Layer
-   **Simple**: A chat-like screen where students search for concepts, see beautiful explanation cards, and can save them as PDFs.
-   **Technical**: A Flutter `ConsumerStatefulWidget` listens to `aiProvider` (Riverpod). It uses `pw.Document` from the `pdf` package to build a PDF document in memory. For the "Attach to Note" feature, it converts the PDF to bytes and uploads it via a `MultipartFile` POST request to the existing Resource API.

## 💻 Full Implementation Code

### Backend (Spring Boot)

#### GeminiService.java
```java
package com.academicproject.eduvisionbackend.service;

import com.academicproject.eduvisionbackend.dto.AiResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.*;

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
                "For any concept provided, you must return a JSON object with exactly three fields: " +
                "\"academicDefinition\", \"simpleDefinition\", and \"examStandardDescription\". " +
                "Respond ONLY with the JSON object.";

        Map<String, Object> requestBody = Map.of("contents", List.of(Map.of("parts", List.of(Map.of("text", systemPrompt + "\n\nConcept: " + prompt)))));

        try {
            String responseStr = restTemplate.postForObject(url, requestBody, String.class);
            JsonNode root = objectMapper.readTree(responseStr);
            String textResponse = root.path("candidates").get(0).path("content").path("parts").get(0).path("text").asText();
            textResponse = textResponse.replaceAll("```json", "").replaceAll("```", "").trim();
            return objectMapper.readValue(textResponse, AiResponse.class);
        } catch (Exception e) {
            return AiResponse.builder().academicDefinition("Error...").build();
        }
    }
}
```

### Frontend (Flutter)

#### AiAssistantScreen.dart (Highlights)
```dart
Future<void> _generateAndSavePdf(AiResponse response, String topic) async {
  final pdf = pw.Document();
  pdf.addPage(pw.MultiPage(build: (context) => [
    pw.Header(level: 0, text: 'EduVision AI - $topic'),
    pw.Header(level: 1, text: 'Academic Definition'),
    pw.Paragraph(text: response.academicDefinition),
    // ... other sections
  ]));
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
```

## 🛠️ Extra Steps

1.  **API Key**: Ensure `gemini.api.key=YOUR_KEY` is present in `application.properties`.
2.  **Flutter Dependencies**: Run `flutter pub get` to install `pdf`, `printing`, and `path_provider`.
3.  **CORS**: The `GeminiController` is annotated with `@CrossOrigin("*")` to allow Flutter Web requests.

## 📝 Summary Workflow

1.  **UI**: Student enters a topic in the `AiAssistantScreen`.
2.  **API**: Request sent to `/api/ai/ask`.
3.  **Gemini**: Backend calls Gemini with a formatting instruction.
4.  **Display**: Three cards (Academic, Simple, Exam) appear with animations.
5.  **Action**: Student clicks "Extract PDF" (local save) or "Attach to Note" (saved to DB as a resource).

---
*Generated by EduVision Project Team* 🚀
