/// Domain model for a Book in the user's personal library.
/// Maps directly to the BookResponseDto from the Spring Boot backend.
class Book {
  final int id;
  final String title;
  final String? author;
  final String? description;
  final String? isbn;
  final String? language;
  final String? category;
  final int? numberOfPages;
  final int? fileSize;
  final String? fileName;
  final bool isFavorite;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.isbn,
    this.language,
    this.category,
    this.numberOfPages,
    this.fileSize,
    this.fileName,
    required this.isFavorite,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'] ?? '',
      author: json['author'],
      description: json['description'],
      isbn: json['isbn'],
      language: json['language'],
      category: json['category'],
      numberOfPages: json['numberOfPages'],
      fileSize: json['fileSize'],
      fileName: json['fileName'],
      isFavorite: json['isFavorite'] ?? false,
      rating: json['rating'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
