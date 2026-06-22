# EduVision – Parallel Front‑end & Back‑end Roadmap (Week‑wise)

## Week 1 – Project Setup
- **Backend**: Initialise Spring Boot project with Maven. Add core dependencies (`spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `spring-boot-starter-security`, `jjwt`, `mysql‑connector‑java`). Create base package structure (`controller`, `service`, `repository`, `dto`, `entity`, `security`, `config`). Add `EduvisionBackendApplication.java`.
- **Frontend**: Initialise Flutter web project (`flutter create . --platforms=web`). Add core packages (`riverpod`, `dio`, `go_router`, `flutter_secure_storage`). Create folder layout (`presentation`, `domain`, `data`).
- **Goal**: Verify both servers start (`./mvnw spring-boot:run` and `flutter run -d chrome`).

## Week 2 – Authentication (Backend + Frontend)
- **Backend**: Implement `User` entity, DTOs (`LoginRequest`, `SignupRequest`, `AuthResponse`). Build `UserRepository`, `AuthService` (BCrypt + JWT), security config (`JwtAuthenticationFilter`, `SecurityConfig`). Add `AuthController` with `/api/auth/login` and `/api/auth/signup`. Write unit and integration tests.
- **Frontend**: Create `LoginPage` & `SignupPage` with form validation. Define `User` domain model, `AuthRemoteDataSource` (Dio) and `AuthRepositoryImpl`. Add Riverpod `AuthProvider` (`StateNotifier`) and GoRouter guard to protect routes. Write widget tests.
- **Shared API**: `POST /api/auth/signup` and `POST /api/auth/login` returning `{ token, user }`. Store JWT via `flutter_secure_storage`.

## Week 3 – Notes Management (Backend + Frontend)
- **Backend**: Define `Note` entity (markdown content, subject, topic, bookmarked). Create DTOs (`NoteCreateDto`, `NoteUpdateDto`, `NoteResponseDto`). Implement `NoteRepository` with search method, `NoteService` (CRUD, toggle bookmark, pagination), and `NoteController` (`/api/notes/**`). Add tests.
- **Frontend**: Build `Note` domain model and use‑cases (`CreateNote`, `UpdateNote`, `DeleteNote`, `SearchNotes`, `ToggleBookmark`). Implement `NoteRemoteDataSource` (Dio) and `NoteRepositoryImpl`. Create UI pages: `NotesListPage`, `NoteEditPage`, `NoteViewPage` (markdown preview). Manage state with Riverpod `NotesProvider`. Add search bar with debounce and bookmark toggle. Write widget tests.
- **Shared API**: CRUD endpoints plus `PATCH /api/notes/{id}/bookmark`.

## Week 4 – Resources (PDF & YouTube) (Backend + Frontend)
- **Backend**: Create `Resource` entity (type ENUM {PDF,YOUTUBE}, title, url, filePath). Add DTOs, `ResourceRepository`, `ResourceService` (multipart PDF upload, YouTube link validation), and `ResourceController`. Store uploaded PDFs under `uploads/`. Write tests for file handling.
- **Frontend**: Define `Resource` model and use‑cases (`UploadPdf`, `AddYoutubeLink`, `FetchResources`, `DeleteResource`). Implement `ResourceRemoteDataSource` (multipart Dio) and `ResourceRepositoryImpl`. Build UI: `ResourcesPage` (grid of cards), `UploadPdfDialog`, `AddYoutubeDialog`. Use `flutter_pdfview` (or Syncfusion) for PDF preview and `youtube_player_iframe` for YouTube embeds. Write tests.
- **Shared API**: `POST /api/resources/pdf`, `POST /api/resources/youtube`, `GET /api/resources`, `DELETE /api/resources/{id}`.

## Week 5 – AI Assistant (Backend + Frontend)
- **Backend**: Add `GeminiAiService` that calls Gemini REST API. Create DTOs (`AiRequestDto` with `type` = SUMMARY/FLASHCARD/ASK and `prompt`, `AiResponseDto`). Implement `AiController` (`/api/ai/generate`). Externalise Gemini API key in `application.yml`. Add global exception handling and mock‑server tests.
- **Frontend**: Define `AiResult` model and use‑case `GenerateAiResult`. Build `AiRemoteDataSource` (Dio POST) and `AiRepositoryImpl`. Design `AiAssistantPage` (text input, dropdown for request type, Generate button, result display). Manage state with Riverpod provider. Write widget tests with mocked repository.
- **Shared API**: `POST /api/ai/generate` → `{ content }`.

## Week 6 – Flashcards (Optional Stretch) (Backend + Frontend)
- **Backend**: Create `Flashcard` entity (question, answer, dueDate, interval). Add DTOs, `FlashcardRepository`, `FlashcardService` (generate from note text, simple SM‑2 scheduling). Provide `FlashcardController` (`/api/flashcards/**`). Write unit tests for spaced‑repetition logic.
- **Frontend**: Build `Flashcard` domain model and use‑cases (`GenerateFromNote`, `ReviewFlashcard`). Implement `FlashcardRemoteDataSource` and `FlashcardRepositoryImpl`. Create `FlashcardReviewPage` (show question → reveal answer → grade). Manage with Riverpod `FlashcardProvider`. Write widget tests.
- **Shared API**: `POST /api/flashcards`, `GET /api/flashcards?due=true`, `PUT /api/flashcards/{id}`.

## Ongoing Cross‑Cutting Concerns (apply each week)
- **Error handling**: Backend `@ControllerAdvice` → uniform JSON; Frontend central error widget (`SnackBar`/dialog).
- **Logging**: SLF4J + Logback on backend; `package:logging` + Dio interceptors on Flutter.
- **CORS**: Configure Spring CORS to allow the web UI origin.
- **API versioning**: Prefix routes with `/api/v1/`; reflect in Flutter base URL.
- **Environment configuration**: Use Maven profiles (`dev`, `prod`) and `flutter_dotenv` for Dart.
- **Testing**: Keep unit, widget, and integration tests up‑to‑date each sprint.
- **Documentation**: Swagger UI for backend, `dartdoc` for Flutter.
- **Security**: Store JWT securely, use HTTPS in production.

---

*Follow the weeks sequentially, but feel free to adjust pacing as needed. When you finish a week, let me know which part you’d like deeper guidance on, and I’ll provide the exact code snippets and explanations.*
