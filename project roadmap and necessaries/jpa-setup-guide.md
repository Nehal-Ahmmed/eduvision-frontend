# JPA Setup Guide for Spring Boot with MySQL

## Step 1: Verify Dependencies

Add to `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <scope>runtime</scope>
</dependency>
```

---

## Step 2: Database Configuration

Edit `src/main/resources/application.properties`:

```properties
# MySQL Connection Settings
spring.datasource.url=jdbc:mysql://localhost:3306/your_database_name
spring.datasource.username=root
spring.datasource.password=your_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA / Hibernate Settings
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
```

> **Note on `ddl-auto`:**
> - `update` — Auto-updates the schema to match your Java classes (recommended for development)
> - `none` — Leaves the schema untouched

---

## Step 3: Create the Entity Class

```java
@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String username;
    private String email;
}
```

---

## Step 4: Create the Repository Interface

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Spring generates the SQL automatically
    Optional<User> findByUsername(String username);
}
```

---

## Step 5: Use in Your Service

```java
@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public User saveUser(User user) {
        return userRepository.save(user);       // INSERT
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();         // SELECT *
    }
}
```
