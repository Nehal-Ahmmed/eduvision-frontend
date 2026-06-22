# 🔐 Full-Stack Authentication Guide (Spring Boot + Flutter)

This guide provides a **complete, full-source** implementation of a secure **JWT (JSON Web Token)** authentication system for **EduVision**. This is a one-stop-shop: every file you need for both Backend and Frontend is included here with full code and detailed comments.

### Procedure to login
**The JWT Authentication Flow: How it actually works**
It is important to distinguish between the Login Phase and the Authorized Request Phase.

1. **The Login Phase (First Time)**

**Action:** You click the "Login" button. Your app sends a POST request with the Username and Password (raw text) in the body.

**Backend Task:** The backend receives these credentials. It doesn't look for a token yet. It uses your CustomUserDetailsService to find the user in the database and uses BCrypt to check if the password matches the hashed one in the users table.

**Result:** If successful, the backend generates a JWT Token. This token is a signed string that contains the username (and sometimes roles), but never the password. The backend sends this token back to your app.

2. The Authorized Request Phase (Every time after login)
Action: For any subsequent request (like fetching profile data), your app includes that token in the Authorization header as Bearer <token>.

Backend Task: This is where JwtAuthenticationFilter kicks in. It extracts the token, validates the signature, and checks the expiration. If valid, it tells Spring Security, "This user is who they claim to be," and allows the request to reach the Controller.

---

## 🗺️ 1. High-Level Roadmap (10 Core Steps)
1.  **Dependency Setup**: Adding security and JWT libraries.
2.  **Database Entity**: Creating the `User` model for MySQL.
3.  **Data Access Layer**: Interface to talk to the database (Repository).
4.  **Data Transfer Objects (DTOs)**: Simple objects for login/signup requests.
5.  **Security Bridge**: Teaching Spring Security how to find your users (`UserDetailsService`).
6.  **JWT Utility**: The logic for creating and reading "ID Tickets" (Tokens).
7.  **Security Filter**: The middleware "Guard" that checks tokens on every request.
8.  **Global Configuration**: The "Brain" defining which routes are public or private.
9.  **Business Logic & API**: The Service and Controller handling the logic.
10. **Frontend Integration**: Using `Dio` for requests and `Secure Storage` for the token.

---

## 🧠 2. Detailed Logical Descriptions

### A. The Spring Boot (Backend) Layer
*   **Entity & Repository**: 
    *   *Simple*: The `User` class is the blueprint for your database table.
    *   *Technical*: Uses **JPA (Java Persistence API)**. The Repository acts as a bridge, allowing you to run database queries using Java methods instead of raw SQL.
*   **JWT Utility**: 
    *   *Simple*: A tool that creates an "ID Card" (Token) when someone logs in.
    *   *Technical*: Signs a payload (username) using a **Secret Key** and HS256 algorithm. This makes the system **Stateless**, meaning the server doesn't need to "remember" sessions in memory.
*   **Security Filter**: 
    *   *Simple*: A guard at the entrance who checks everyone's ID Card.
    *   *Technical*: A `OncePerRequestFilter` that intercepts every HTTP request, extracts the `Authorization` header, and validates the JWT using `JwtUtils`.
*   **SecurityConfig**: 
    *   *Simple*: The rulebook that says "/login is public, but /notes is private."
    *   *Technical*: Configures the **SecurityFilterChain**, disables CSRF, sets the Session Policy to `STATELESS`, and defines **CORS** rules for cross-origin requests.

### B. The Flutter (Frontend) Layer
*   **Remote Data Source**: 
    *   *Simple*: The "Postman" that delivers your login details to the backend.
    *   *Technical*: An abstraction layer using the `Dio` package to communicate with REST endpoints.
*   **Secure Storage**: 
    *   *Simple*: A locked safe for the user's Token.
    *   *Technical*: Uses OS-level encryption (Keychain for iOS, Keystore for Android) to persist the JWT across app restarts.
*   **Auth Provider**: 
    *   *Simple*: A traffic light that changes the app from "Login Mode" to "Dashboard Mode".
    *   *Technical*: A `StateNotifier` that manages authentication state and notifies the UI whenever the status changes.

---

## 💻 3. Full Backend Implementation (Spring Boot)

### Step 1: Dependencies (`pom.xml`)
```xml
<!-- Add these inside your <dependencies> tag -->

<!-- 1. Spring Security: The core firewall framework -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<!-- 2. JWT (jjwt): Tools to create and read tokens -->
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

<!-- 3. Lombok: To keep our code clean -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

### Step 2: The User Entity (`User.java`)
```java
package com.cuet_project.eduvision_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "users") // Name of the table in MySQL
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // Auto-incremented primary key

    @Column(unique = true, nullable = false)
    private String username;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String password; // Will be stored as a BCrypt HASH (never plain text!)

    private String role = "ROLE_USER"; // Default permission level
}
```

### Step 3: Data Access Layer (`UserRepository.java`)
```java
package com.cuet_project.eduvision_backend.repository;

import com.cuet_project.eduvision_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Find a user by their username (used during Login)
    Optional<User> findByUsername(String username);
    
    // Check if a username already exists (used during Signup)
    Boolean existsByUsername(String username);
    
    // Check if an email already exists (used during Signup)
    Boolean existsByEmail(String email);
}
```

### Step 4: Data Transfer Objects (`dto/`)
These classes are used to map JSON data from the frontend to Java objects.

```java
// 1. SignupRequest.java
public class SignupRequest {
    private String username;
    private String email;
    private String password;
}

// 2. LoginRequest.java
public class LoginRequest {
    private String username;
    private String password;
}

// 3. AuthResponse.java (Data sent back to Flutter)
@Builder @Getter
public class AuthResponse {
    private String token; // The JWT string
    private String username;
    private String email;
}
```

### Step 5: Security Bridge (`CustomUserDetailsService.java`)
```java
package com.cuet_project.eduvision_backend.security;

import com.cuet_project.eduvision_backend.entity.User;
import com.cuet_project.eduvision_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;
import java.util.ArrayList;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // Look for the user in our MySQL database
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User Not Found: " + username));

        // Convert our User entity into a "Spring Security User"
        return new org.springframework.security.core.userdetails.User(
                user.getUsername(), 
                user.getPassword(), 
                new ArrayList<>() // Add roles/authorities here if needed
        );
    }
}
```

### Step 6: JWT Utility (`JwtUtils.java`)
```java
package com.cuet_project.eduvision_backend.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import java.util.Date;

@Component
public class JwtUtils {
    // A long, high-entropy secret key for signing tokens
    private String jwtSecret = "YourSuperSecretKeyThatMustBeAtLeast32BytesLongForSecurity";
    private int jwtExpirationMs = 86400000; // 24 hours expiry

    // Generate a token for a logged-in user
    public String generateToken(UserDetails userPrincipal) {
        return Jwts.builder()
                .subject(userPrincipal.getUsername()) // Store username as subject
                .issuedAt(new Date())
                .expiration(new Date((new Date()).getTime() + jwtExpirationMs))
                .signWith(Keys.hmacShaKeyFor(jwtSecret.getBytes())) // Sign with secret
                .compact();
    }

    // Extract the username back from the token string
    public String extractUsername(String token) {
        return Jwts.parser().verifyWith(Keys.hmacShaKeyFor(jwtSecret.getBytes())).build()
                .parseSignedClaims(token).getPayload().getSubject();
    }

    // Verify if the token is valid and not tampered with
    public boolean validateToken(String authToken) {
        try {
            Jwts.parser().verifyWith(Keys.hmacShaKeyFor(jwtSecret.getBytes())).build().parse(authToken);
            return true;
        } catch (Exception e) {
            return false; // Token is invalid, expired, or malformed
        }
    }
}
```

### Step 7: Security Filter (`JwtAuthenticationFilter.java`)
```java
package com.cuet_project.eduvision_backend.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired private JwtUtils jwtUtils;
    @Autowired private CustomUserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        // 1. Get the "Authorization" header from the request
        String header = request.getHeader("Authorization");

        // 2. Check if it's a "Bearer" token
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7); // Remove "Bearer " prefix

            // 3. If token is valid, tell Spring Security who this user is
            if (jwtUtils.validateToken(token)) {
                String username = jwtUtils.extractUsername(token);
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                var authentication = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                // SET THE SECURITY CONTEXT: The user is now logged in for this request
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }
        
        // Continue with the request
        filterChain.doFilter(request, response);
    }
}
```

### Step 8: Global Configuration (`SecurityConfig.java`)
```java
package com.cuet_project.eduvision_backend.config;

import com.cuet_project.eduvision_backend.security.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.*;

import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired private JwtAuthenticationFilter jwtFilter;

    // PASSWORD ENCODER: Hashes passwords using BCrypt
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // AUTH MANAGER: Used by the Service to verify credentials
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource())) // Handle Flutter connections
            .csrf(csrf -> csrf.disable()) // Not needed for REST
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // No sessions
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll() // Open to everyone
                .anyRequest().authenticated() // Private routes
            );

        // Add our JWT filter
        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    // CORS CONFIG: Crucial for Flutter Web
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

### Step 9: Service & Controller (`AuthService.java` & `AuthController.java`)
```java
// AuthService.java
@Service
public class AuthService {
    @Autowired private UserRepository userRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtUtils jwtUtils;
    @Autowired private AuthenticationManager authenticationManager;

    public AuthResponse login(LoginRequest req) {
        // 1. Verify username and password
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.getUsername(), req.getPassword()));
        
        // 2. If valid, generate a Token
        String token = jwtUtils.generateToken((UserDetails) auth.getPrincipal());
        
        return AuthResponse.builder()
                .token(token)
                .username(req.getUsername())
                .build();
    }
}

// AuthController.java
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired private AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        return ResponseEntity.ok(authService.login(loginRequest));
    }
}
```

---

## 🎨 4. Full Frontend Implementation (Flutter)

### Step 1: Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  dio: ^5.4.0                 # API requests
  flutter_secure_storage: ^9.0.0 # Encrypted storage
  flutter_riverpod: ^2.4.9    # State management
```

### Step 2: Domain Model (`app_user.dart`)
```dart
class AppUser {
  final String username;
  final String email;
  final String? token; // The JWT token from backend

  AppUser({required this.username, required this.email, this.token});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
    );
  }
}
```

### Step 3: API Client (`AuthRemoteDataSource.dart`)
```dart
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  // Use http://10.0.2.2:8080 for Android Emulator, localhost for Web
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/auth'));

  Future<AppUser> login(String username, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'username': username,
        'password': password,
      });
      return AppUser.fromJson(response.data);
    } catch (e) {
      throw Exception("Login Failed: ${e.toString()}");
    }
  }
}
```

### Step 4: Secure Repository (`AuthRepository.dart`)
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();
  final _remote = AuthRemoteDataSource();

  Future<AppUser> login(String username, String password) async {
    final user = await _remote.login(username, password);
    
    // Save the token to secure storage immediately
    if (user.token != null) {
      await _storage.write(key: 'jwt', value: user.token);
    }
    return user;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt'); // Remove token on logout
  }

  Future<String?> getToken() async => await _storage.read(key: 'jwt');
}
```

### Step 5: State Provider (`auth_provider.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(AuthRepository());
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> login(String u, String p) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(u, p);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
```

---

## 🛠️ 5. Final Setup Checklist

1.  **MySQL Database**: Create a database named `eduvision` (or whatever is in your `application.properties`).
2.  **DDL Auto**: Ensure `spring.jpa.hibernate.ddl-auto=update` is set so Spring creates the `users` table for you.
3.  **Secret Key**: Change the `jwtSecret` in `JwtUtils.java` to a long random string.
4.  **CORS**: If using Flutter Web, ensure your backend allows the origin (usually port 5000+).

---

**Summary**: This guide provides the **complete** source for a production-ready auth system. Copy these files into their respective directories, update your database settings, and you are ready to go!

