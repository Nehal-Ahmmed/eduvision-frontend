# 🗺️ High-Level Roadmap

1. **Database Schema Enhancements**: Extended the JPA PostgreSQL `Note` entity with `isFolder` (boolean flag) and `parentId` (Long reference to support hierarchical subfolders) columns.
2. **DTO & Serialization Updates**: Modified `NoteCreateDto` and `NoteResponseDto` to carry these fields between the client and API server seamlessly.
3. **Repository Layer Extension**: Added native list querying (`findByUser`) to retrieve flat hierarchies without pagination to easily build file explorer trees.
4. **Service & Controller Logic**: Modified `NoteService` to handle folder/file node mappings and created the `/all` endpoint in `NoteController` for one-pass tree hydration.
5. **State Synchronization Architecture (Riverpod)**: Defined the `activeNoteIdProvider` to establish a single source of truth for the currently opened note across widgets.
6. **Network & State Hydration**: Refactored `NoteRemoteDataSource` and `NotesNotifier` in Riverpod to handle recursive fetching, folder creation, and note content saving via PUT requests.
7. **Recursive Tree Explorer View**: Fully integrated `smart_notes_left_sidebar.dart` to consume Riverpod state, build hierarchical nested `NoteNode`s, filter with a live search bar, and map selections to `activeNoteIdProvider`.
8. **Interactive Editor Canvas View**: Overhauled `smart_notes_editor_area.dart` to bind its input fields to the currently selected note, reactively loading database content and saving changes to the backend on clicking "Save".

---

# 🧠 Logical Descriptions

## Backend Layer (Spring Boot)
- **Simple Description**: Instead of storing folders and files in separate tables, the database treats everything as a "Note Node". A Folder is simply a note with `isFolder = true` and no content. To put something inside a folder, we tell the database: "This file/folder has a parent folder with ID X".
- **Technical Description**: The `Note` entity utilizes a self-referencing relationship where `parentId` points to the ID of another `Note` record. All entities belonging to the current `User` are queried in a single call via `findByUser(User user)` to prevent "N+1" lazy loading problems. The `/all` controller endpoint serializes the list as JSON containing flat nodes.

## Frontend Layer (Flutter)
- **Simple Description**: The left explorer sidebar loads all folders and files from the database. It organizes them into a nice nested file tree (like folders in Windows Explorer or VS Code). Users can click a folder to select it as the active directory, and then click "Create Folder" or "Create Note" to instantly add subfolders or notes inside it! Clicking a note loads its content in the editor canvas, which tracks your inputs and saves them securely to the database when you hit Save.
- **Technical Description**: The UI watches the Riverpod `notesProvider` (holding `AsyncValue<List<Note>>`) and `activeNoteIdProvider` (holding the current selection state). An algorithm `buildTree` recursively scans the flat list of notes, matching their `parentId` to construct a nested `List<NoteNode>` tree. The editor canvas implements a `ConsumerStatefulWidget` and handles text input state using a `TextEditingController` which is reactively loaded using a microtask when `activeNoteId` changes.

---

# 💻 Full Implementation Code

## 1. POM Dependencies (`eduvisionbackend/pom.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>3.2.5</version>
		<relativePath/>
	</parent>
	<groupId>com.academicproject</groupId>
	<artifactId>eduvisionbackend</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<properties>
		<java.version>21</java.version>
	</properties>
	<dependencies>
		<!-- Core Spring Framework starter -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<!-- Spring Data JPA for Database communication -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-jpa</artifactId>
		</dependency>
		<!-- PostgreSQL Database Driver -->
		<dependency>
			<groupId>org.postgresql</groupId>
			<artifactId>postgresql</artifactId>
			<scope>runtime</scope>
		</dependency>
		<!-- Lombok for automated Getters, Setters, and Builders -->
		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>
		<!-- Security and Authentication -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-security</artifactId>
		</dependency>
	</dependencies>
</project>
```

## 2. Note JPA Entity (`entity/Note.java`)
```java
package com.academicproject.eduvisionbackend.entity;

import java.time.LocalDateTime;
import java.util.List;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "notes")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Note {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Content is nullable (folders don't have text contents)
    @Column(columnDefinition = "TEXT")
    private String content;

    // Subject is nullable for folder groupings
    @Column
    private String subject;

    // Topic holds either the note title or folder name
    @Column
    private String topic;

    @Column(name = "is_folder", nullable = false)
    @Builder.Default
    private boolean isFolder = false;

    // Self-referencing link to the parent folder node
    @Column(name = "parent_id")
    private Long parentId;

    private boolean bookmarked = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @OneToMany(mappedBy = "note", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Resource> resources;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

## 3. Note Repository (`repository/NoteRepository.java`)
```java
package com.academicproject.eduvisionbackend.repository;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import com.academicproject.eduvisionbackend.entity.Note;
import com.academicproject.eduvisionbackend.entity.User;

public interface NoteRepository extends JpaRepository<Note, Long> {
    // Paginated search for notes
    Page<Note> findByUser(User user, Pageable pageable);

    // List search without pagination to build the complete explorer tree hierarchy
    List<Note> findByUser(User user);

    Page<Note> findByUserAndSubjectContainingIgnoreCaseOrTopicContainingIgnoreCase(
            User user, String subject, String topic, Pageable pageable);

    List<Note> findByUserAndBookmarkedTrue(User user);
}
```

## 4. Note DTOs (`dto/NoteCreateDto.java` & `dto/NoteResponseDto.java`)
### `NoteCreateDto.java`
```java
package com.academicproject.eduvisionbackend.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class NoteCreateDto {
    private String content;
    private String subject;
    private String topic;
    private boolean isFolder;
    private Long parentId;
}
```

### `NoteResponseDto.java`
```java
package com.academicproject.eduvisionbackend.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class NoteResponseDto {
    private Long id;
    private String content;
    private String subject;
    private String topic;
    private boolean bookmarked;
    private boolean isFolder;
    private Long parentId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<ResourceResponseDto> resources;
}
```

## 5. Note Service (`service/NoteService.java`)
```java
package com.academicproject.eduvisionbackend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

import com.academicproject.eduvisionbackend.dto.NoteCreateDto;
import com.academicproject.eduvisionbackend.dto.NoteResponseDto;
import com.academicproject.eduvisionbackend.dto.ResourceResponseDto;
import com.academicproject.eduvisionbackend.entity.Note;
import com.academicproject.eduvisionbackend.entity.User;
import com.academicproject.eduvisionbackend.repository.NoteRepository;
import com.academicproject.eduvisionbackend.repository.UserRepository;

@Service
public class NoteService {

    @Autowired
    private NoteRepository noteRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ResourceService resourceService;

    private User getCurrentUser() {
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return userRepository.findByUsername(userDetails.getUsername()).orElseThrow();
    }

    @Transactional
    public NoteResponseDto createNote(NoteCreateDto dto) {
        User user = getCurrentUser();
        Note note = Note.builder()
                .content(dto.getContent())
                .subject(dto.getSubject())
                .topic(dto.getTopic())
                .isFolder(dto.isFolder())
                .parentId(dto.getParentId())
                .user(user)
                .build();
        Note saved = noteRepository.save(note);
        return mapToDto(saved);
    }

    @Transactional(readOnly = true)
    public List<NoteResponseDto> getAllNotesList() {
        User user = getCurrentUser();
        return noteRepository.findByUser(user).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<NoteResponseDto> getAllNotes(Pageable pageable) {
        User user = getCurrentUser();
        return noteRepository.findByUser(user, pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public NoteResponseDto getNoteById(Long id) {
        Note note = noteRepository.findById(id).orElseThrow();
        if (!note.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        return mapToDto(note);
    }

    @Transactional
    public NoteResponseDto updateNote(Long id, NoteCreateDto dto) {
        Note note = noteRepository.findById(id).orElseThrow();
        if (!note.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        note.setContent(dto.getContent());
        note.setSubject(dto.getSubject());
        note.setTopic(dto.getTopic());
        note.setFolder(dto.isFolder());
        note.setParentId(dto.getParentId());
        return mapToDto(noteRepository.save(note));
    }

    public void deleteNote(Long id) {
        Note note = noteRepository.findById(id).orElseThrow();
        if (!note.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        noteRepository.delete(note);
    }

    @Transactional
    public NoteResponseDto toggleBookmark(Long id) {
        Note note = noteRepository.findById(id).orElseThrow();
        if (!note.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        note.setBookmarked(!note.isBookmarked());
        return mapToDto(noteRepository.save(note));
    }

    public NoteResponseDto mapToDto(Note note) {
        List<ResourceResponseDto> resourceDtos = null;
        if (note.getResources() != null) {
            resourceDtos = note.getResources().stream()
                    .map(resource -> resourceService.mapToDto(resource))
                    .collect(Collectors.toList());
        }

        return NoteResponseDto.builder()
                .id(note.getId())
                .content(note.getContent())
                .subject(note.getSubject())
                .topic(note.getTopic())
                .bookmarked(note.isBookmarked())
                .isFolder(note.isFolder())
                .parentId(note.getParentId())
                .createdAt(note.getCreatedAt())
                .updatedAt(note.getUpdatedAt())
                .resources(resourceDtos)
                .build();
    }
}
```

## 6. Note REST Controller (`controller/NoteController.java`)
```java
package com.academicproject.eduvisionbackend.controller;

import com.academicproject.eduvisionbackend.dto.NoteCreateDto;
import com.academicproject.eduvisionbackend.dto.NoteResponseDto;
import com.academicproject.eduvisionbackend.service.NoteService;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notes")
public class NoteController {

    @Autowired
    private NoteService noteService;

    @PostMapping
    public ResponseEntity<NoteResponseDto> createNote(@RequestBody NoteCreateDto dto) {
        return ResponseEntity.ok(noteService.createNote(dto));
    }

    @GetMapping
    public ResponseEntity<Page<NoteResponseDto>> getAllNotes(Pageable pageable) {
        return ResponseEntity.ok(noteService.getAllNotes(pageable));
    }

    @GetMapping("/all")
    public ResponseEntity<List<NoteResponseDto>> getAllNotesList() {
        return ResponseEntity.ok(noteService.getAllNotesList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<NoteResponseDto> getNoteById(@PathVariable Long id) {
        return ResponseEntity.ok(noteService.getNoteById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<NoteResponseDto> updateNote(@PathVariable Long id, @RequestBody NoteCreateDto dto) {
        return ResponseEntity.ok(noteService.updateNote(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteNote(@PathVariable Long id) {
        noteService.deleteNote(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/bookmark")
    public ResponseEntity<NoteResponseDto> toggleBookmark(@PathVariable Long id) {
        return ResponseEntity.ok(noteService.toggleBookmark(id));
    }
}
```

## 7. Flutter Domain Model (`lib/domain/note.dart`)
```dart
import 'resource.dart';

class Note {
  final int id;
  final String content;
  final String subject;
  final String topic;
  final bool bookmarked;
  final bool isFolder;
  final int? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Resource> resources;

  Note({
    required this.id,
    required this.content,
    required this.subject,
    required this.topic,
    required this.bookmarked,
    required this.isFolder,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.resources = const [],
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      bookmarked: json['bookmarked'] ?? false,
      isFolder: json['isFolder'] ?? false,
      parentId: json['parentId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      resources: json['resources'] != null
          ? (json['resources'] as List).map((r) => Resource.fromJson(r)).toList()
          : [],
    );
  }
}
```

## 8. Flutter Remote Data Source (`lib/data/note_remote_data_source.dart`)
```dart
import 'package:academic_project/domain/note.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NoteRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/notes'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Note>> fetchNotes() async {
    final response = await _dio.get('/all', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Note.fromJson(e)).toList();
  }

  Future<Note> createNote(
    String content,
    String subject,
    String topic, {
    bool isFolder = false,
    int? parentId,
  }) async {
    final response = await _dio.post(
      '',
      data: {
        'content': content,
        'subject': subject,
        'topic': topic,
        'isFolder': isFolder,
        'parentId': parentId,
      },
      options: await _getOptions(),
    );
    return Note.fromJson(response.data);
  }

  Future<Note> createFolder(String name, {int? parentId}) async {
    return createNote(
      '',
      'Folder',
      name,
      isFolder: true,
      parentId: parentId,
    );
  }

  Future<Note> updateNote(
    int id,
    String content,
    String subject,
    String topic,
  ) async {
    final response = await _dio.put(
      '/$id',
      data: {'content': content, 'subject': subject, 'topic': topic},
      options: await _getOptions(),
    );
    return Note.fromJson(response.data);
  }

  Future<void> deleteNote(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }

  Future<Note> toggleBookmark(int id) async {
    final response = await _dio.patch(
      '/$id/bookmark',
      options: await _getOptions(),
    );
    return Note.fromJson(response.data);
  }
}
```

## 9. Flutter Riverpod Provider (`lib/presentation/smart notes/provider/notes_provider.dart`)
```dart
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
  }) async {
    try {
      await _dataSource.createNote(content, subject, topic, parentId: parentId);
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

  Future<void> updateNote(int id, String content, String subject, String topic) async {
    try {
      await _dataSource.updateNote(id, content, subject, topic);
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
```

## 10. Flutter Tree Explorer Sidebar (`lib/presentation/smart notes/screens/smart_notes_left_sidebar.dart`)
*(Please refer directly to your [smart_notes_left_sidebar.dart](file:///d:/fullStack%20Projects/academic_project/EduVision/lib/presentation/smart%20notes/screens/smart_notes_left_sidebar.dart) file, which contains the complete recursive `buildTree` parsing algorithm, search query text matching, and visual active state selections).*

## 11. Flutter Editor Canvas (`lib/presentation/smart notes/screens/smart_notes_editor_area.dart`)
*(Please refer directly to your [smart_notes_editor_area.dart](file:///d:/fullStack%20Projects/academic_project/EduVision/lib/presentation/smart%20notes/screens/smart_notes_editor_area.dart) file, which contains the complete input text bindings, microtask content syncing, and database save methods).*

---

# 🛠️ Extra Steps

- **Database Automatic Updates**: The Spring Boot JPA engine is configured with `spring.jpa.hibernate.ddl-auto=update`. When starting up, Hibernate automatically generates the migrations to alter the existing `notes` table and add `is_folder` and `parent_id` columns without data loss.
- **Tree Render Optimization**: On search operations, filtering is executed *prior* to tree building. This ensures unmatched leaves are removed, leaving a slimmed tree that fits inside the visible browser view area.

---

# 📝 Summary

1. **User Interaction**: User enters a folder name or note title in the interactive UI dialogues on the **Smart Notes** sidebar.
2. **State dispatch**: The `notesProvider` notifier dispatches `createFolder()` or `addNote()` along with the active directory's `parentId`.
3. **API Post Request**: `Dio` marshals this structure to `POST /api/notes` with a JWT authorization header token.
4. **Spring Execution**: `NoteController` intercepts the payload, maps it to a database entity, relates it to the currently authenticated `User`, and executes `noteRepository.save()`.
5. **Database Transaction**: PostgreSQL inserts the node record, generating a unique `id` and tying it hierarchically to its parent node.
6. **Reactive Refresh**: Upon a successful server response, the Riverpod state issues an automatic `fetchNotes()` to fetch the updated `/all` database layout, refreshing the sidebar.
