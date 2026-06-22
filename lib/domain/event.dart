enum EventType {
  EXAM,
  DEADLINE,
  LECTURE,
  GROUP,
  OTHER;

  static EventType fromString(String type) {
    return EventType.values.firstWhere(
      (e) => e.name == type.toUpperCase(),
      orElse: () => EventType.OTHER,
    );
  }
}

class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final EventType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.location,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  bool get isUpcoming => eventDate.isAfter(DateTime.now()) || isToday;

  String get formattedDate {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final day = eventDate.day.toString().padLeft(2, '0');
    return '${months[eventDate.month - 1]} $day, ${eventDate.year}';
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: DateTime.parse(json['eventDate']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
      type: EventType.fromString(json['type'] ?? 'OTHER'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
