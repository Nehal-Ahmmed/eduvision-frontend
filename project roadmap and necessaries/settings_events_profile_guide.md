# 🛠️ Settings, Events & Profile Enhancement Guide

---

## 🗺️ High-Level Roadmap

1. **Backend — Settings API**: Created `UserSettings` entity, repository, DTO, service, and controller for persistent user preferences (theme, language, notifications).
2. **Backend — Image Upload Fix**: Increased `spring.servlet.multipart.max-file-size` and `max-request-size` to `10MB` in `application.properties`.
3. **Flutter — Settings Remote Data Source**: Created `SettingsRemoteDataSource` with model, GET and PUT API calls.
4. **Flutter — Settings Provider (Riverpod)**: Created `SettingsNotifier` to manage theme, language, and notification state reactively.
5. **Flutter — Dynamic Theme in `main.dart`**: `MyApp` now watches `settingsProvider` and applies `lightTheme`/`darkTheme` dynamically from DB.
6. **Flutter — Settings Screen UI**: Built full professional Settings screen with sections: Appearance, Language, Notifications, Account, About.
7. **Flutter — Profile Image Upload Fix**: Fixed `profile_service.dart` to detect content-type from file extension (PNG, WEBP, HEIC, etc.).
8. **Flutter — Profile UI Redesign**: Achievements, Activities, and Schedule sections redesigned with premium cards, emoji medals, tags, and structured layouts.
9. **Flutter — Events Screen Redesign**: Replaced placeholder with a full Events screen — tabs, filter chips, color-coded event cards, Add Event dialog.
10. **Navigation**: Registered `/settings` route in `GoRouter` and added `SettingsScreen` import.

---

## 🧠 Logical Descriptions

### Backend Layer

| Feature | Simple | Technical |
|---|---|---|
| User Settings Storage | Save each user's theme/language/notifications in the DB | `UserSettings` JPA entity linked `OneToOne` to `User`, persisted via `UserSettingsRepository` |
| Settings API | GET and PUT endpoints at `/api/settings` | `UserSettingsController` → `UserSettingsService` → `UserSettingsRepository` |
| Image Upload Fix | Allow uploading large images up to 10MB | `spring.servlet.multipart.max-file-size=10MB` in `application.properties` |

### Frontend Layer

| Feature | Simple | Technical |
|---|---|---|
| Dynamic Theme | Toggle dark/light theme from Settings screen | `settingsProvider` watches backend state; `main.dart` applies `AppTheme.darkTheme` or `lightTheme` |
| Settings Screen | Professional settings UI with all sections | `SettingsScreen` → `_SettingsContent` ConsumerWidget using Riverpod, calls `SettingsNotifier` |
| Image Upload Fix | Any image format now uploads correctly | Detect MIME type from extension in `uploadProfileImage`, pass as `DioMediaType` to Dio |
| Profile Sections | Premium cards for achievements, activities, schedule | Emoji medal icons, color-coded tags, structured rows with role/name separation |
| Events Screen | Filter chips, colored event types, clean cards | `EventsScreen` StatefulWidget with filter state, `_buildEventCard` per event type |

---

## 💻 Full Implementation Code

### Backend

#### [NEW] `entity/UserSettings.java`
```java
@Entity
@Table(name = "user_settings")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserSettings {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false) @Builder.Default private String theme = "light";
    @Column(nullable = false) @Builder.Default private String language = "en";
    @Column(name = "email_notifications") @Builder.Default private boolean emailNotifications = true;
    @Column(name = "push_notifications")  @Builder.Default private boolean pushNotifications = true;
}
```

#### [NEW] `dto/UserSettingsDto.java`
```java
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UserSettingsDto {
    private String theme;
    private String language;
    private boolean emailNotifications;
    private boolean pushNotifications;
}
```

#### [NEW] `controller/UserSettingsController.java`
```java
@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class UserSettingsController {
    private final UserSettingsService userSettingsService;

    @GetMapping
    public ResponseEntity<UserSettingsDto> getSettings(Authentication auth) {
        return ResponseEntity.ok(userSettingsService.getSettings(auth.getName()));
    }

    @PutMapping
    public ResponseEntity<UserSettingsDto> updateSettings(Authentication auth, @RequestBody UserSettingsDto dto) {
        return ResponseEntity.ok(userSettingsService.updateSettings(auth.getName(), dto));
    }
}
```

#### `application.properties` additions
```properties
# File Upload Configuration (fixes high-res image upload errors)
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

### Frontend

#### `lib/data/settings_remote_datasource.dart`
- Model: `UserSettingsModel` with `fromJson`, `toJson`, `copyWith`
- `fetchSettings()`: GET `/api/settings`
- `updateSettings(UserSettingsModel)`: PUT `/api/settings`

#### `lib/presentation/settings/provider/settings_provider.dart`
- `SettingsNotifier` extends `StateNotifier<AsyncValue<UserSettingsModel>>`
- Methods: `updateTheme()`, `updateLanguage()`, `toggleEmailNotifications()`, `togglePushNotifications()`
- Optimistic update: state updates immediately, then syncs to backend

#### `lib/main.dart`
```dart
final themeStr = settingsVal.maybeWhen(
  data: (s) => s.theme,
  orElse: () => 'light',
);
theme: themeStr == 'dark' ? AppTheme.darkTheme : AppTheme.lightTheme,
```

#### `lib/presentation/profile/services/profile_service.dart` — Image Upload Fix
```dart
final ext = fileName.split('.').last.toLowerCase();
final contentType = switch (ext) {
  'png'         => 'image/png',
  'jpg'||'jpeg' => 'image/jpeg',
  'webp'        => 'image/webp',
  'heic'||'heif'=> 'image/heic',
  _             => 'application/octet-stream',
};
MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType.parse(contentType))
```

---

## 🛠️ Extra Steps

### Database
The `UserSettings` table is **auto-created by Hibernate** (`spring.jpa.hibernate.ddl-auto=update`). No manual migration needed.

### Environment
No new environment variables needed.

### Running the App
```bash
# Backend
cd eduvisionbackend
.\mvnw.cmd spring-boot:run

# Frontend
flutter run -d chrome
```

---

## 📝 Summary — Data Flow

```
User clicks "Dark Mode" toggle in Settings Screen
  → settingsProvider.notifier.updateTheme('dark')
    → State updates immediately (optimistic)
      → UI rebuilds → main.dart applies AppTheme.darkTheme
    → SettingsRemoteDataSource.updateSettings(...)
      → PUT http://localhost:8080/api/settings (with JWT)
        → UserSettingsController → UserSettingsService
          → UserSettings entity updated in PostgreSQL DB
```

```
User opens app again
  → SettingsNotifier.loadSettings()
    → GET http://localhost:8080/api/settings
      → DB returns saved theme/language/notifications
        → settingsProvider state loaded
          → main.dart applies correct theme automatically
```
