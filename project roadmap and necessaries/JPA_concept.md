## JPA(Java Persistence API)
JPA is a specification for accessing, persisting, and managing data between Java objects and relational databases.

### ORM (Object relational Mapping)
JPA is based on Object-Relational Mapping (ORM).

1. Object: Java Classes (Entities).
2. Relational: Database Tables.
3. Mapping: Metadata (Annotations or XML) that defines how Java fields map to table columns.

### JPA vs. Hibernate
1. JPA is a Specification: It is a set of interfaces and rules (a "blueprint"). It cannot perform operations on its own.
2. Hibernate is an Implementation: It is the actual library (a "provider") that implements the JPA interfaces. Spring Boot uses Hibernate by default.

### Key Components
1. **Entity**: A lightweight persistence domain object (a Java class marked with @Entity).
2. **EntityManager**: The primary interface used to interact with the persistence context (perform CRUD operations).
3. **Persistence Context**: A first-level cache where all entity instances are managed.
4. **JPQL (Java Persistence Query Language)**: An object-oriented query language used to perform database operations using entities instead of table names.

