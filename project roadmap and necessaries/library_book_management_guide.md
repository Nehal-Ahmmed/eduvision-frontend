# 📚 Library Book Soft Copy Management Guide

## 1. 🗺️ High-Level Roadmap

1.  **Frontend Layout Fix**: Added proper search inputs and real-time dropdowns to filter books via the `LibrarySidebar`.
2.  **State Management**: Configured Riverpod (`LibraryProvider`) for state management connecting the UI directly to the `BookRemoteDataSource`.
3.  **Backend Auth Fix**: `BookService` was using `findByEmail` when the JWT token actually contained `username`. This caused a "User not found" exception during file uploads. Changed to `findByUsername`.
4.  **Error Propagation**: Updated `LibraryProvider` to correctly catch and re-throw API exceptions, ensuring the "Success" toast doesn't incorrectly trigger on failures.
5.  **Download Functionality**: 
    *   Split the "Read / Download" single button into dedicated `Read` (Inline view) and `Download` (Direct file save) buttons.
    *   Added `?download=true` flag.
    *   Updated `JwtAuthenticationFilter.java` in Spring Security to fallback to a URL query parameter `?token=...` when handling native browser downloads.

---

## 2. 🧠 Logical Descriptions

### Frontend Layer (Simple vs Technical)
*   **Simple**: You go to the Library section. You can search books by title or author, filter by category/language, read them online, or download them to your device as PDFs.
*   **Technical**: Flutter Riverpod binds the `LibrarySidebar` inputs directly to the state. Real-time updates query `BookRemoteDataSource`, which uses `Dio` with a Bearer JWT Token. File downloads utilize `url_launcher` sending authenticated requests via URL parameters (`?token=JWT&download=true`).

### Backend Layer (Simple vs Technical)
*   **Simple**: The backend stores the book's metadata in the database and saves the physical PDF to your disk.
*   **Technical**: Spring Boot endpoints in `BookController.java` consume `MultipartFile` and DTO strings. `JwtAuthenticationFilter` validates user security via `Authorization` Header OR URL Query Params (crucial for `<a href>` downloads). The `/files/{id}` endpoint manipulates the `Content-Disposition` HTTP header dynamically (`inline` vs `attachment`).

---

## 3. 💻 Full Implementation Code

### A. Backend - `JwtAuthenticationFilter.java`
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

        // Required for url_launcher downloads from Flutter
        String tokenParam = request.getParameter("token");
        if (tokenParam != null && !tokenParam.isEmpty()) {
            return tokenParam;
        }

        return null;
    }
}
```

### B. Backend - `BookController.java`
```java
package com.academicproject.eduvisionbackend.controller;

import com.academicproject.eduvisionbackend.dto.BookCreateDto;
import com.academicproject.eduvisionbackend.dto.BookResponseDto;
import com.academicproject.eduvisionbackend.entity.Book;
import com.academicproject.eduvisionbackend.service.BookService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

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

    @GetMapping("/files/{id}")
    public ResponseEntity<Resource> getBookFile(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "false") boolean download) throws IOException {
        logger.info("[book download] Request received for book ID: {}, download param: {}", id, download);
        try {
            Book book = bookService.getBookEntityById(id);
            logger.info("[book download] Found book record in DB: '{}' by author '{}'. File storage path: '{}'", 
                    book.getTitle(), book.getAuthor(), book.getFilePath());

            // Query Supabase Storage REST API
            String downloadUrl = supabaseUrl + "/storage/v1/object/" + supabaseBucket + "/" + book.getFilePath();
            logger.info("[book download] Fetching from Supabase Storage URL: {}", downloadUrl);

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + supabaseKey);
            headers.set("apiKey", supabaseKey);
            
            HttpEntity<Void> entity = new HttpEntity<>(headers);
            ResponseEntity<byte[]> response = restTemplate.exchange(downloadUrl, HttpMethod.GET, entity, byte[].class);

            byte[] fileBytes = response.getBody();
            if (fileBytes == null) {
                return ResponseEntity.notFound().build();
            }

            ByteArrayResource resource = new ByteArrayResource(fileBytes);
            String contentType = response.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE);
            if (contentType == null) {
                contentType = "application/pdf";
            }

            String dispositionType = download ? "attachment" : "inline";

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
}
```

### C. Frontend - `book_remote_data_source.dart`
```dart
  // =========================================
  // Book file download URL (for reading/opening)
  // =========================================

  Future<String> getBookFileUrl(int bookId) async {
    final token = await _storage.read(key: 'jwt');
    return 'http://localhost:8080/api/books/files/$bookId?token=$token';
  }
```

### D. Frontend - `library_book_details.dart` (Read & Download Logic)
```dart
                // Read & Download buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Read Button
                    GestureDetector(
                      onTap: () async {
                        print('[book download] Read button tapped for book ID: ${book.id}');
                        try {
                          final url = await dataSource.getBookFileUrl(book.id);
                          print('[book download] Read button URL: $url');
                          final uri = Uri.parse(url);
                          final canLaunch = await canLaunchUrl(uri);
                          print('[book download] Read button canLaunchUrl: $canLaunch');
                          if (canLaunch) {
                            print('[book download] Launching Read URL via externalApplication...');
                            final success = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            print('[book download] Read launchUrl success status: $success');
                          } else {
                            print('[book download] Error: cannot launch Read URL: $url');
                          }
                        } catch (e, stack) {
                          print('[book download] Exception in Read tap: $e');
                          print('[book download] Stack trace: $stack');
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE29F5C), Color(0xFF8B5115)]),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(1, 2), blurRadius: 2)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text("Read", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Download Button
                    GestureDetector(
                      onTap: () async {
                        print('[book download] Download button tapped for book ID: ${book.id}');
                        try {
                          final baseUrl = await dataSource.getBookFileUrl(book.id);
                          final url = '$baseUrl&download=true';
                          print('[book download] Download URL: $url');
                          
                          // Use unified cross-platform download helper
                          downloadFile(url, book.fileName ?? 'book.pdf');
                          print('[book download] Download triggered successfully via downloadFile helper');
                        } catch (e, stack) {
                          print('[book download] Exception in Download tap: $e');
                          print('[book download] Stack trace: $stack');
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC73024),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(1, 2), blurRadius: 2)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text("Download", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
```

### E. Frontend - Cross-Platform Unified Download Helper

We use Dart conditional imports to select the correct implementation programmatically without breaking multi-platform compilations (Web, iOS, Android, Desktop).

#### 📁 `lib/utils/download_helper.dart` (Unified Wrapper)
```dart
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

/// Triggers a file download on the client device.
/// Uses native HTML anchors on web to prevent connection abortions/navigating away,
/// and uses standard url_launcher on other platforms.
void downloadFile(String url, String fileName) {
  downloadFileImpl(url, fileName);
}
```

#### 📁 `lib/utils/download_helper_stub.dart` (Fallback Interface)
```dart
void downloadFileImpl(String url, String fileName) {
  throw UnsupportedError('downloadFile is not supported on this platform.');
}
```

#### 📁 `lib/utils/download_helper_web.dart` (Web Implementation)
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
```

#### 📁 `lib/utils/download_helper_mobile.dart` (Mobile/Desktop Implementation)
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
```

---

## 4. 🛠️ Extra Steps
1. **Pgbouncer Warning**: Required configuring `spring.datasource.hikari.data-source-properties.prepareThreshold=0` in `application.properties` to solve "Prepared Statement" issues with Supabase database pooling.
2. **Postgres Setup**: The `books` table structure is configured directly by Hibernate (via `@Entity` Book.java). 

---

## 5. 📝 Summary
1. The User presses **Read** or **Download**.
2. If **Read**: The app opens the file inline using `LaunchMode.externalApplication` (opens in a new tab).
3. If **Download**: 
   * **On Web**: A hidden `<a>` HTML element is programmatically created, mapped to the download URL, configured with the `download` attribute containing the filename, added to the document body, clicked programmatically, and cleaned up. This prevents the current tab from navigating away and ensures the WebSocket/TCP session is not closed/aborted.
   * **On Mobile/Desktop**: The system launches the download link using an external browser app.
4. The backend `BookController.java` serves the file from the local server disk.
5. The download finishes cleanly without connection abort warning messages.

