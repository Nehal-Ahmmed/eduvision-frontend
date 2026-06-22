import 'resource.dart';

class Note {
  final int id;
  final String content;
  final String subject;
  final String topic;
  final bool bookmarked;
  final bool isFolder;
  final int? parentId;
  final String tags;
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
    this.tags = '',
    required this.createdAt,
    required this.updatedAt,
    this.resources = const [],
  });

  List<String> get tagList => tags.isEmpty ? [] : tags.split(',').map((t) => t.trim()).toList();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      bookmarked: json['bookmarked'] ?? false,
      isFolder: json['isFolder'] ?? false,
      parentId: json['parentId'],
      tags: json['tags'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      resources: json['resources'] != null
          ? (json['resources'] as List).map((r) => Resource.fromJson(r)).toList()
          : [],
    );
  }
}
