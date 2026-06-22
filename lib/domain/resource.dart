enum ResourceType {
  YOUTUBE,
  PDF,
  IMAGE,
  VIDEO,
  FILE,
  LINK,
  UNKNOWN;

  static ResourceType fromString(String type) {
    return ResourceType.values.firstWhere(
      (e) => e.name == type.toUpperCase(),
      orElse: () => ResourceType.UNKNOWN,
    );
  }
}

class Resource {
  final int id;
  final String title;
  final String resourceUrl;
  final ResourceType type;
  final String? description;
  final DateTime createdAt;
  final int noteId;

  Resource({
    required this.id,
    required this.title,
    required this.resourceUrl,
    required this.type,
    this.description,
    required this.createdAt,
    required this.noteId,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      title: json['title'],
      resourceUrl: json['resourceUrl'],
      type: ResourceType.fromString(json['type']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      noteId: json['noteId'],
    );
  }
}
