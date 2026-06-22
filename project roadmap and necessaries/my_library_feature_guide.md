# 📚 My Library Feature Guide: Supabase Storage Integration

Welcome to the comprehensive implementation guide for the **My Library** feature in the EduVision app! This guide reflects the production-grade migration of book PDF storage from the local server filesystem to **Supabase Storage buckets**, securing endpoints via a backend proxy and implementing a cross-platform, compile-safe download helper.

---

## 1. 🗺️ High-Level Roadmap

1. **Supabase PostgreSQL & Storage Setup**: Linked the PostgreSQL database (via pooler connection) and configured a bucket named `books` in Supabase Storage.
2. **Backend Configuration**: Set up credentials in `application.properties` including `supabase.url`, `supabase.key`, and `supabase.bucket`.
3. **Backend Entity Layer**: Built the `Book` JPA entity to store metadata and the Supabase Storage object path (e.g., `books/uuid_filename.pdf`).
4. **Backend Security Enhancements**: Updated `JwtAuthenticationFilter` to authenticate REST requests via standard Authorization headers and fallback URL query parameters (`?token=...`), which is crucial for native browser triggers.
5. **Backend Service & API Layer**:
   - Updated `BookService` to upload raw binary data to the Supabase REST API via `RestTemplate` and delete files on delete requests.
   - Configured `BookController` as a secure download/read proxy that streams bytes from the Supabase API to the user without exposing API keys.
6. **Frontend Conditional Imports**: Created a cross-platform download wrapper (`download_helper.dart`) to avoid web socket/TCP aborts by simulating HTML anchor clicks on Web target.
7. **Frontend Data & State**: Integrated Riverpod (`booksProvider`) and the updated `BookRemoteDataSource` to connect the shelves and details screen.

---

## 2. 🧠 Logical Descriptions

### Backend Layer
* **Simple Description**: The backend acts as a secure shipping gateway. Instead of storing the PDFs on the local computer's drive, it streams them to a secure cloud warehouse (Supabase Storage). When a student wants to download a book, the backend authenticates the student, fetches the book's secret file bytes from the cloud warehouse using the admin credentials, and hands it safely to the student.
* **Technical Description**: Spring Boot routes HTTP calls securely. When uploading a file, `BookService` generates a unique storage path and uses a `RestTemplate` `POST` request with a Bearer Authorization header containing the Supabase API Key to:
  `${supabase.url}/storage/v1/object/${supabase.bucket}/books/{uuid_name.pdf}`.
  When downloading, `BookController` serves files by performing an authenticated `GET` call to the Supabase REST endpoint, wrapping the returned payload into a `ByteArrayResource`, setting headers for inline/attachment serving, and streaming it directly.

### Frontend Layer
* **Simple Description**: The frontend draws a beautiful library screen. When you search or open a book, it gets the listing from the server. Tapping the "Download" button starts a hidden file downloader in the browser that fetches the book bytes and saves it, without interrupting what you're doing.
* **Technical Description**: The Flutter Web app coordinates state using Riverpod. The details view triggers a call to `BookRemoteDataSource` to obtain a secure transient URL of the proxy server (`/api/books/files/{id}?token={jwt}`). The cross-platform `downloadFile` helper uses conditional compilation (`dart.library.html` vs `dart.library.io`) to programmatically insert an HTML `AnchorElement` on web targets, programmatically triggering a browser download request without disrupting state, animations, or sockets.

---

## 3. 💻 Full Implementation Code

Here is the full, copy-pasteable source code for all components involved.

### 🐘 Backend (Spring Boot)

#### 📄 `pom.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>3.2.5</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.academicproject</groupId>
	<artifactId>eduvisionbackend</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>eduvisionbackend</name>
	<description>EduVision Academic Backend</description>
	<properties>
		<java.version>21</java.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-jpa</artifactId>
		</dependency>
		<dependency>
			<groupId>org.postgresql</groupId>
			<artifactId>postgresql</artifactId>
			<scope>runtime</scope>
		</dependency>
		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-security</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-devtools</artifactId>
			<scope>runtime</scope>
			<optional>true</optional>
		</dependency>
		<dependency>
			<groupId>io.jsonwebtoken</groupId>
			<artifactId>jjwt-api</artifactId>
			<version>0.12.5</version>
		</dependency>
		<dependency>
			<groupId>io.jsonwebtoken</groupId>
			<artifactId>jjwt-impl</artifactId>
			<version>0.12.5</version>
			<scope>runtime</scope>
		</dependency>
		<dependency>
			<groupId>io.jsonwebtoken</groupId>
			<artifactId>jjwt-jackson</artifactId>
			<version>0.12.5</version>
			<scope>runtime</scope>
		</dependency>
	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>
</project>
```

#### 📄 `Book.java` (Entity)
```java
package com.academicproject.eduvisionbackend.entity;

import java.time.LocalDateTime;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "books")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column
    private String author;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column
    private String isbn;

    @Column
    private String language;

    @Column
    private String category;

    @Column
    private Integer numberOfPages;

    // Supabase storage object path (e.g. books/uuid-filename.pdf)
    @Column(nullable = false, columnDefinition = "TEXT")
    private String filePath;

    @Column
    private Long fileSize;

    @Column
    private String fileName;

    @Column(name = "is_favorite", nullable = false)
    @Builder.Default
    private boolean isFavorite = false;

    @Column
    @Builder.Default
    private Integer rating = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

#### 📄 `BookRepository.java`
```java
package com.academicproject.eduvisionbackend.repository;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.academicproject.eduvisionbackend.entity.Book;
import com.academicproject.eduvisionbackend.entity.User;

public interface BookRepository extends JpaRepository<Book, Long> {

    Page<Book> findByUser(User user, Pageable pageable);

    List<Book> findByUser(User user);

    long countByUser(User user);

    @Query("SELECT b FROM Book b WHERE b.user = :user " +
           "AND (:query IS NULL OR LOWER(b.title) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "    OR LOWER(b.author) LIKE LOWER(CONCAT('%', :query, '%'))) " +
           "AND (:category IS NULL OR LOWER(b.category) = LOWER(:category)) " +
           "AND (:author IS NULL OR LOWER(b.author) LIKE LOWER(CONCAT('%', :author, '%'))) " +
           "AND (:language IS NULL OR LOWER(b.language) = LOWER(:language))")
    List<Book> searchBooks(
            @Param("user") User user,
            @Param("query") String query,
            @Param("category") String category,
            @Param("author") String author,
            @Param("language") String language);

    @Query("SELECT DISTINCT b.category FROM Book b WHERE b.user = :user AND b.category IS NOT NULL")
    List<String> findDistinctCategoriesByUser(@Param("user") User user);

    @Query("SELECT DISTINCT b.author FROM Book b WHERE b.user = :user AND b.author IS NOT NULL")
    List<String> findDistinctAuthorsByUser(@Param("user") User user);

    @Query("SELECT DISTINCT b.language FROM Book b WHERE b.user = :user AND b.language IS NOT NULL")
    List<String> findDistinctLanguagesByUser(@Param("user") User user);
}
```

#### 📄 `BookCreateDto.java`
```java
package com.academicproject.eduvisionbackend.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class BookCreateDto {
    private String title;
    private String author;
    private String description;
    private String isbn;
    private String language;
    private String category;
    private Integer numberOfPages;
}
```

#### 📄 `BookResponseDto.java`
```java
package com.academicproject.eduvisionbackend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class BookResponseDto {
    private Long id;
    private String title;
    private String author;
    private String description;
    private String isbn;
    private String language;
    private String category;
    private Integer numberOfPages;
    private Long fileSize;
    private String fileName;

    @JsonProperty("isFavorite")
    private boolean isFavorite;

    private Integer rating;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

#### 📄 `BookService.java`
```java
package com.academicproject.eduvisionbackend.service;

import com.academicproject.eduvisionbackend.dto.BookCreateDto;
import com.academicproject.eduvisionbackend.dto.BookResponseDto;
import com.academicproject.eduvisionbackend.entity.Book;
import com.academicproject.eduvisionbackend.entity.User;
import com.academicproject.eduvisionbackend.repository.BookRepository;
import com.academicproject.eduvisionbackend.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;

import java.io.IOException;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class BookService {

    @Autowired
    private BookRepository bookRepository;

    @Autowired
    private UserRepository userRepository;

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

    @Value("${supabase.bucket}")
    private String supabaseBucket;

    private final RestTemplate restTemplate = new RestTemplate();

    private User getCurrentUser() {
        UserDetails userDetails = (UserDetails) SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getPrincipal();

        return userRepository
                .findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @Transactional
    public BookResponseDto uploadBook(
            MultipartFile file,
            String title,
            String author,
            String description,
            String isbn,
            String language,
            String category,
            Integer numberOfPages) throws IOException {

        User user = getCurrentUser();

        // Unique cloud directory layout
        String uniqueFileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
        String storagePath = "books/" + uniqueFileName;

        // REST request to Supabase Storage API
        String uploadUrl = supabaseUrl + "/storage/v1/object/" + supabaseBucket + "/" + storagePath;
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + supabaseKey);
        headers.set("apiKey", supabaseKey);
        
        String contentType = file.getContentType();
        if (contentType == null) {
            contentType = "application/octet-stream";
        }
        headers.setContentType(MediaType.parseMediaType(contentType));
        
        HttpEntity<byte[]> entity = new HttpEntity<>(file.getBytes(), headers);
        
        try {
            restTemplate.postForEntity(uploadUrl, entity, String.class);
        } catch (Exception e) {
            throw new RuntimeException("Failed to upload file to Supabase Storage: " + e.getMessage(), e);
        }

        Book book = Book.builder()
                .title(title)
                .author(author)
                .description(description)
                .isbn(isbn)
                .language(language)
                .category(category)
                .numberOfPages(numberOfPages)
                .filePath(storagePath)
                .fileSize(file.getSize())
                .fileName(file.getOriginalFilename())
                .user(user)
                .build();

        return mapToDto(bookRepository.save(book));
    }

    @Transactional(readOnly = true)
    public Page<BookResponseDto> getAllBooks(Pageable pageable) {
        User user = getCurrentUser();
        return bookRepository.findByUser(user, pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public List<BookResponseDto> getAllBooksList() {
        User user = getCurrentUser();
        return bookRepository.findByUser(user).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public BookResponseDto getBookById(Long id) {
        Book book = bookRepository.findById(id).orElseThrow(
                () -> new RuntimeException("Book not found"));
        if (!book.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        return mapToDto(book);
    }

    @Transactional(readOnly = true)
    public Book getBookEntityById(Long id) {
        Book book = bookRepository.findById(id).orElseThrow(
                () -> new RuntimeException("Book not found"));
        if (!book.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        return book;
    }

    @Transactional
    public BookResponseDto updateBook(Long id, BookCreateDto dto) {
        Book book = bookRepository.findById(id).orElseThrow(
                () -> new RuntimeException("Book not found"));
        if (!book.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }

        book.setTitle(dto.getTitle());
        book.setAuthor(dto.getAuthor());
        book.setDescription(dto.getDescription());
        book.setIsbn(dto.getIsbn());
        book.setLanguage(dto.getLanguage());
        book.setCategory(dto.getCategory());
        book.setNumberOfPages(dto.getNumberOfPages());

        return mapToDto(bookRepository.save(book));
    }

    @Transactional
    public void deleteBook(Long id) {
        Book book = bookRepository.findById(id).orElseThrow(
                () -> new RuntimeException("Book not found"));
        if (!book.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }

        // Send REST delete request to cloud storage bucket
        String deleteUrl = supabaseUrl + "/storage/v1/object/" + supabaseBucket + "/" + book.getFilePath();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + supabaseKey);
        headers.set("apiKey", supabaseKey);
        
        HttpEntity<Void> entity = new HttpEntity<>(headers);
        
        try {
            restTemplate.exchange(deleteUrl, HttpMethod.DELETE, entity, Void.class);
        } catch (Exception e) {
            System.err.println("Warning: failed to delete file from Supabase Storage: " + e.getMessage());
        }

        bookRepository.delete(book);
    }

    @Transactional
    public BookResponseDto toggleFavorite(Long id) {
        Book book = bookRepository.findById(id).orElseThrow(
                () -> new RuntimeException("Book not found"));
        if (!book.getUser().getId().equals(getCurrentUser().getId())) {
            throw new RuntimeException("Unauthorized");
        }
        book.setFavorite(!book.isFavorite());
        return mapToDto(bookRepository.save(book));
    }

    @Transactional(readOnly = true)
    public List<BookResponseDto> searchBooks(String query, String category, String author, String language) {
        User user = getCurrentUser();
        return bookRepository.searchBooks(user, query, category, author, language)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long getBookCount() {
        User user = getCurrentUser();
        return bookRepository.countByUser(user);
    }

    @Transactional(readOnly = true)
    public List<String> getDistinctCategories() {
        User user = getCurrentUser();
        return bookRepository.findDistinctCategoriesByUser(user);
    }

    @Transactional(readOnly = true)
    public List<String> getDistinctAuthors() {
        User user = getCurrentUser();
        return bookRepository.findDistinctAuthorsByUser(user);
    }

    @Transactional(readOnly = true)
    public List<String> getDistinctLanguages() {
        User user = getCurrentUser();
        return bookRepository.findDistinctLanguagesByUser(user);
    }

    private BookResponseDto mapToDto(Book book) {
        return BookResponseDto.builder()
                .id(book.getId())
                .title(book.getTitle())
                .author(book.getAuthor())
                .description(book.getDescription())
                .isbn(book.getIsbn())
                .language(book.getLanguage())
                .category(book.getCategory())
                .numberOfPages(book.getNumberOfPages())
                .fileSize(book.getFileSize())
                .fileName(book.getFileName())
                .isFavorite(book.isFavorite())
                .rating(book.getRating())
                .createdAt(book.getCreatedAt())
                .updatedAt(book.getUpdatedAt())
                .build();
    }
}
```

#### 📄 `BookController.java`
```java
package com.academicproject.eduvisionbackend.controller;

import com.academicproject.eduvisionbackend.dto.BookCreateDto;
import com.academicproject.eduvisionbackend.dto.BookResponseDto;
import com.academicproject.eduvisionbackend.entity.Book;
import com.academicproject.eduvisionbackend.service.BookService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/books")
public class BookController {

    private static final Logger logger = LoggerFactory.getLogger(BookController.class);

    @Autowired
    private BookService bookService;

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

    @Value("${supabase.bucket}")
    private String supabaseBucket;

    private final RestTemplate restTemplate = new RestTemplate();

    @PostMapping("/upload")
    public ResponseEntity<BookResponseDto> uploadBook(
            @RequestParam("file") MultipartFile file,
            @RequestParam("title") String title,
            @RequestParam(value = "author", required = false) String author,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "isbn", required = false) String isbn,
            @RequestParam(value = "language", required = false) String language,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "numberOfPages", required = false) Integer numberOfPages) throws IOException {

        return ResponseEntity.ok(bookService.uploadBook(
                file, title, author, description, isbn, language, category, numberOfPages));
    }

    @GetMapping
    public ResponseEntity<Page<BookResponseDto>> getAllBooks(Pageable pageable) {
        return ResponseEntity.ok(bookService.getAllBooks(pageable));
    }

    @GetMapping("/all")
    public ResponseEntity<List<BookResponseDto>> getAllBooksList() {
        return ResponseEntity.ok(bookService.getAllBooksList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookResponseDto> getBookById(@PathVariable Long id) {
        return ResponseEntity.ok(bookService.getBookById(id));
    }

    @GetMapping("/files/{id}")
    public ResponseEntity<Resource> getBookFile(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "false") boolean download) throws IOException {
        logger.info("[book download] Request received for book ID: {}, download param: {}", id, download);
        try {
            Book book = bookService.getBookEntityById(id);
            logger.info("[book download] Found book record in DB: '{}' by author '{}'. File storage path: '{}'", 
                    book.getTitle(), book.getAuthor(), book.getFilePath());

            String downloadUrl = supabaseUrl + "/storage/v1/object/" + supabaseBucket + "/" + book.getFilePath();
            logger.info("[book download] Fetching from Supabase Storage URL: {}", downloadUrl);

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + supabaseKey);
            headers.set("apiKey", supabaseKey);
            
            HttpEntity<Void> entity = new HttpEntity<>(headers);
            
            ResponseEntity<byte[]> response;
            try {
                response = restTemplate.exchange(downloadUrl, HttpMethod.GET, entity, byte[].class);
            } catch (Exception e) {
                logger.error("[book download] Error downloading from Supabase Storage: {}", e.getMessage());
                return ResponseEntity.notFound().build();
            }

            byte[] fileBytes = response.getBody();
            if (fileBytes == null) {
                logger.warn("[book download] Received empty content from Supabase Storage");
                return ResponseEntity.notFound().build();
            }

            logger.info("[book download] File successfully retrieved from Supabase Storage. Size: {} bytes", fileBytes.length);

            ByteArrayResource resource = new ByteArrayResource(fileBytes);

            String contentType = response.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE);
            if (contentType == null) {
                contentType = "application/pdf";
            }
            logger.info("[book download] Content-Type: {}", contentType);

            String dispositionType = download ? "attachment" : "inline";
            logger.info("[book download] Content-Disposition type: {}, filename: '{}'", dispositionType, book.getFileName());

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, dispositionType + "; filename=\"" + book.getFileName() + "\"")
                    .contentLength(fileBytes.length)
                    .body(resource);
        } catch (Exception e) {
            logger.error("[book download] Error serving file for book ID: {}. Exception: ", id, e);
            throw e;
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<BookResponseDto> updateBook(
            @PathVariable Long id,
            @RequestBody BookCreateDto dto) {
        return ResponseEntity.ok(bookService.updateBook(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBook(@PathVariable Long id) {
        bookService.deleteBook(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/favorite")
    public ResponseEntity<BookResponseDto> toggleFavorite(@PathVariable Long id) {
        return ResponseEntity.ok(bookService.toggleFavorite(id));
    }

    @GetMapping("/search")
    public ResponseEntity<List<BookResponseDto>> searchBooks(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String author,
            @RequestParam(required = false) String language) {
        return ResponseEntity.ok(bookService.searchBooks(query, category, author, language));
    }

    @GetMapping("/count")
    public ResponseEntity<Map<String, Long>> getBookCount() {
        return ResponseEntity.ok(Map.of("count", bookService.getBookCount()));
    }

    @GetMapping("/filters/categories")
    public ResponseEntity<List<String>> getCategories() {
        return ResponseEntity.ok(bookService.getDistinctCategories());
    }

    @GetMapping("/filters/authors")
    public ResponseEntity<List<String>> getAuthors() {
        return ResponseEntity.ok(bookService.getDistinctAuthors());
    }

    @GetMapping("/filters/languages")
    public ResponseEntity<List<String>> getLanguages() {
        return ResponseEntity.ok(bookService.getDistinctLanguages());
    }
}
```

#### 📄 `JwtAuthenticationFilter.java`
```java
package com.academicproject.eduvisionbackend.security;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String jwt = parseJwt(request);
            if (jwt != null) {
                String username = jwtUtils.getUsernameFromToken(jwt);

                UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                if (jwtUtils.validateToken(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        } catch (Exception e) {
            logger.error("Cannot set user authentication: {}", e);
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");

        if (headerAuth != null && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }

        // For direct browser downloads
        String tokenParam = request.getParameter("token");
        if (tokenParam != null && !tokenParam.isEmpty()) {
            return tokenParam;
        }

        return null;
    }
}
```

---

### 📱 Frontend (Flutter Web / Cross-Platform)

#### 📁 `lib/utils/download_helper.dart` (Unified Entry point)
```dart
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

/// Triggers a compile-safe file download on the client device.
/// Uses native HTML anchors on web to prevent connection abortions,
/// and uses standard url_launcher on other platforms.
void downloadFile(String url, String fileName) {
  downloadFileImpl(url, fileName);
}

/// Opens a file in a new tab/window for inline viewing/reading.
/// Uses native HTML window open on web to prevent context navigation,
/// and uses standard url_launcher on other platforms.
void viewFile(String url) {
  viewFileImpl(url);
}
```

#### 📁 `lib/utils/download_helper_stub.dart`
```dart
void downloadFileImpl(String url, String fileName) {
  throw UnsupportedError('downloadFile is not supported on this platform.');
}

void viewFileImpl(String url) {
  throw UnsupportedError('viewFile is not supported on this platform.');
}
```

#### 📁 `lib/utils/download_helper_web.dart`
```dart
import 'dart:html' as html;

void downloadFileImpl(String url, String fileName) {
  print('[book download] Web execution: initiating anchor download for file: $fileName');
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..target = '_blank'
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  print('[book download] Web execution: anchor click event dispatched');
}

void viewFileImpl(String url) {
  print('[book download] Web execution: opening PDF URL in a new window/tab: $url');
  html.window.open(url, '_blank');
  print('[book download] Web execution: window open dispatched');
}
```

#### 📁 `lib/utils/download_helper_mobile.dart`
```dart
import 'package:url_launcher/url_launcher.dart';

void downloadFileImpl(String url, String fileName) async {
  print('[book download] Mobile/Desktop execution: launching external application for URL: $url');
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('[book download] Mobile/Desktop execution error: cannot launch URL: $url');
  }
}

void viewFileImpl(String url) async {
  print('[book download] Mobile/Desktop execution: viewing URL in external application: $url');
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('[book download] Mobile/Desktop execution error: cannot launch URL: $url');
  }
}
```

#### 📁 `lib/data/book_remote_data_source.dart`
```dart
import 'package:academic_project/domain/book.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/books'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Options> _getOptions() async {
    final token = await _storage.read(key: 'jwt');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Book>> fetchBooks() async {
    final response = await _dio.get('/all', options: await _getOptions());
    final List data = response.data;
    return data.map((e) => Book.fromJson(e)).toList();
  }

  Future<Book> uploadBook({
    required List<int> fileBytes,
    required String fileName,
    required String title,
    String? author,
    String? description,
    String? isbn,
    String? language,
    String? category,
    int? numberOfPages,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final options = await _getOptions();
    options.contentType = 'multipart/form-data';

    final response = await _dio.post(
      '/upload',
      data: formData,
      queryParameters: {
        'title': title,
        if (author != null) 'author': author,
        if (description != null) 'description': description,
        if (isbn != null) 'isbn': isbn,
        if (language != null) 'language': language,
        if (category != null) 'category': category,
        if (numberOfPages != null) 'numberOfPages': numberOfPages,
      },
      options: options,
    );
    return Book.fromJson(response.data);
  }

  Future<Book> getBookById(int id) async {
    final response = await _dio.get('/$id', options: await _getOptions());
    return Book.fromJson(response.data);
  }

  Future<Book> updateBook(
    int id, {
    required String title,
    String? author,
    String? description,
    String? isbn,
    String? language,
    String? category,
    int? numberOfPages,
  }) async {
    final response = await _dio.put(
      '/$id',
      data: {
        'title': title,
        'author': author,
        'description': description,
        'isbn': isbn,
        'language': language,
        'category': category,
        'numberOfPages': numberOfPages,
      },
      options: await _getOptions(),
    );
    return Book.fromJson(response.data);
  }

  Future<void> deleteBook(int id) async {
    await _dio.delete('/$id', options: await _getOptions());
  }

  Future<Book> toggleFavorite(int id) async {
    final response = await _dio.patch(
      '/$id/favorite',
      options: await _getOptions(),
    );
    return Book.fromJson(response.data);
  }

  Future<List<Book>> searchBooks({
    String? query,
    String? category,
    String? author,
    String? language,
  }) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null && category.isNotEmpty) 'category': category,
        if (author != null && author.isNotEmpty) 'author': author,
        if (language != null && language.isNotEmpty) 'language': language,
      },
      options: await _getOptions(),
    );
    final List data = response.data;
    return data.map((e) => Book.fromJson(e)).toList();
  }

  Future<int> getBookCount() async {
    final response = await _dio.get('/count', options: await _getOptions());
    return response.data['count'];
  }

  Future<List<String>> getCategories() async {
    final response = await _dio.get('/filters/categories', options: await _getOptions());
    return List<String>.from(response.data);
  }

  Future<List<String>> getAuthors() async {
    final response = await _dio.get('/filters/authors', options: await _getOptions());
    return List<String>.from(response.data);
  }

  Future<List<String>> getLanguages() async {
    final response = await _dio.get('/filters/languages', options: await _getOptions());
    return List<String>.from(response.data);
  }

  Future<String> getBookFileUrl(int bookId) async {
    final token = await _storage.read(key: 'jwt');
    return 'http://localhost:8080/api/books/files/$bookId?token=$token';
  }
}
```

#### 📁 `lib/presentation/library/provider/library_provider.dart`
```dart
import 'package:academic_project/data/book_remote_data_source.dart';
import 'package:academic_project/domain/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookDataSourceProvider = Provider((ref) => BookRemoteDataSource());

final booksProvider =
    StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  return BooksNotifier(ref.watch(bookDataSourceProvider));
});

final activeBookIdProvider = StateProvider<int?>((ref) => null);

final bookCountProvider = StateProvider<int>((ref) => 0);

final bookCategoriesProvider =
    StateNotifierProvider<FilterListNotifier, AsyncValue<List<String>>>((ref) {
  return FilterListNotifier(
    () => ref.watch(bookDataSourceProvider).getCategories(),
  );
});

final bookAuthorsProvider =
    StateNotifierProvider<FilterListNotifier, AsyncValue<List<String>>>((ref) {
  return FilterListNotifier(
    () => ref.watch(bookDataSourceProvider).getAuthors(),
  );
});

final bookLanguagesProvider =
    StateNotifierProvider<FilterListNotifier, AsyncValue<List<String>>>((ref) {
  return FilterListNotifier(
    () => ref.watch(bookDataSourceProvider).getLanguages(),
  );
});

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRemoteDataSource _dataSource;

  BooksNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await _dataSource.fetchBooks();
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> uploadBook({
    required List<int> fileBytes,
    required String fileName,
    required String title,
    String? author,
    String? description,
    String? isbn,
    String? language,
    String? category,
    int? numberOfPages,
  }) async {
    try {
      await _dataSource.uploadBook(
        fileBytes: fileBytes,
        fileName: fileName,
        title: title,
        author: author,
        description: description,
        isbn: isbn,
        language: language,
        category: category,
        numberOfPages: numberOfPages,
      );
      await fetchBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw e;
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      await _dataSource.deleteBook(id);
      await fetchBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      await _dataSource.toggleFavorite(id);
      await fetchBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchBooks({
    String? query,
    String? category,
    String? author,
    String? language,
  }) async {
    state = const AsyncValue.loading();
    try {
      final books = await _dataSource.searchBooks(
        query: query,
        category: category,
        author: author,
        language: language,
      );
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class FilterListNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Future<List<String>> Function() _fetcher;

  FilterListNotifier(this._fetcher) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final values = await _fetcher();
      state = AsyncValue.data(values);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

---

## 4. 🛠️ Extra Steps & Configuration

### A. Backend Credentials (`application.properties`)
Update these values in `eduvisionbackend/src/main/resources/application.properties`:
```properties
# Supabase Storage Configuration
supabase.url=https://gbokmjcsddiekdbaaiij.supabase.co
supabase.key=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdib2ttamNzZGRpZWtkYmFhaWlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyNjUyODcsImV4cCI6MjA5Mzg0MTI4N30.Yh5JifHEuuKONnY-6VFuWDEkL5SvvsTXJ0DyamzABm8
supabase.bucket=books
```

### B. Supabase Storage Dashboard Rules
To allow successful upload and download, configure these parameters in your Supabase Dashboard:
1. **Create Bucket**: Ensure a storage bucket named `books` exists (Private is fully secure since the Spring Boot backend acts as an authenticated proxy).
2. **Access Policy Configuration**: If using the **Anon Key**, create an RLS policy for the `books` bucket to enable **SELECT** and **INSERT** access.
   - Go to **Storage -> Policies -> New Policy**.
   - Create a policy that grants permission for SELECT (Read) and INSERT (Upload) requests.

---

## 5. 📝 Summary Workflow

```mermaid
sequenceDiagram
    participant User as Flutter Web Frontend
    participant Backend as Spring Boot Proxy
    participant DB as Supabase PostgreSQL
    participant Cloud as Supabase Storage Bucket

    Note over User: User clicks 'Download' Book
    User->>Backend: Request file endpoint: GET /api/books/files/{id}?token={jwt}&download=true
    Backend->>DB: Verify user identity & fetch Book record path
    DB-->>Backend: Return path (e.g. books/uuid.pdf)
    Backend->>Cloud: Request file bytes: GET /storage/v1/object/books/books/uuid.pdf (Auth: Bearer Key)
    Cloud-->>Backend: Stream file payload bytes
    Backend-->>User: Stream file bytes with Header (Attachment; filename)
    Note over User: File downloads directly via Web Anchor
```
