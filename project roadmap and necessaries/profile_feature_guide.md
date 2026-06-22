# User Profile & File Upload Implementation Guide

## 1. 🗺️ High-Level Roadmap
1. **Database Schema Design**: Created `UserProfile`, `AcademicResult`, `Achievement`, `ExtracurricularActivity`, and `ScheduleItem` entities with One-to-One and Many-to-One relationships linked to the authenticated `User`.
2. **DTO & Service Layer (Backend)**: Built a comprehensive `ProfileDto` and mapped entity relations in `UserProfileService` to handle fetching and updating the entire profile at once.
3. **Image Upload API (Backend)**: Implemented a Multipart file upload system in the backend that saves images locally to an `uploads/` folder and exposes them via a static URL endpoint.
4. **State Management (Frontend)**: Configured Riverpod (`profile_provider.dart`) and Dio (`profile_service.dart`) to manage the HTTP requests securely using JWT tokens from `flutter_secure_storage`.
5. **Dynamic UI (Frontend)**: Rewrote the stateless `ProfileScreen` into a dynamic `ConsumerWidget` that reads from the provider, includes form dialogs for updating lists, and integrates `image_picker` for real gallery uploads.

---

## 2. 🧠 Logical Descriptions

### Backend Layer
- **Simple**: We created a "Profile Folder" in the database that is securely locked to your account. Inside this folder, we keep separate lists for your results, achievements, etc. We also created a local file manager that takes an image from your phone, saves it in the server's `uploads/` folder, and gives the app a URL to view it.
- **Technical**: Entities use `CascadeType.ALL` and `orphanRemoval = true` to allow updating the entire profile graph in a single HTTP `PUT` request without manual deletion queries. The File Upload uses Java `NIO` to persist `MultipartFile` inputs, securely resolving file names with `UUID` to prevent collisions, and serves them via an overridden Spring `Resource` endpoint.

### Frontend Layer
- **Simple**: We replaced the fake, hardcoded text with a live "Provider" that talks to the server. When you click "Edit", it pops up a form, sends the new data to the server, and immediately updates the screen so you can see your changes instantly.
- **Technical**: `profile_screen.dart` uses Riverpod's `ref.watch(profileProvider)` to reactively listen to an `AsyncValue<ProfileDto>`. Dialogs fire methods on the `ProfileNotifier` which delegate to `ProfileService` (Dio) for network I/O. For image uploads, `image_picker` accesses the native gallery, retrieves an `XFile`, and Dio posts it as `FormData`.

---

## 3. 💻 Full Implementation Code

*(Code snippets omitted for brevity, but all backend entities and frontend Dart files have been fully implemented and saved to your workspace in `lib/presentation/profile/` and `eduvisionbackend/src/main/java/com/academicproject/eduvisionbackend/`).*

Key files you can review:
- `UserProfileController.java`, `UserProfileService.java`, `UserProfile.java`
- `profile_screen.dart`, `profile_provider.dart`, `profile_models.dart`, `profile_service.dart`

---

## 4. 🛠️ Extra Steps
1. **Directory Permissions**: Ensure that the `uploads` directory at the root of the Spring Boot application (where `pom.xml` is) has write permissions. Spring Boot will attempt to create it automatically if it doesn't exist.
2. **Flutter Web Support**: `image_picker` works out-of-the-box for Chrome web. However, if testing on Android/iOS later, ensure you add the respective camera/storage permissions to `AndroidManifest.xml` and `Info.plist`.
3. **Run Commands**:
   - Backend: `mvn clean spring-boot:run`
   - Frontend: `flutter run -d chrome`

---

## 5. 📝 Summary
**Data Flow**: 
1. **User interacts**: User taps "Edit" or clicks the camera icon in Flutter.
2. **App Requests**: `ProfileNotifier` dispatches the new data via `Dio` to `http://localhost:8080/api/profile` with the JWT token in the Authorization header.
3. **Server Processes**: Spring Boot verifies the token, matches the authenticated username, updates the PostgreSQL/Supabase DB via Hibernate, and saves files to the disk.
4. **UI Reacts**: The server returns the newly updated `ProfileDto`, Riverpod updates its state, and the UI immediately rebuilds to reflect the changes!
