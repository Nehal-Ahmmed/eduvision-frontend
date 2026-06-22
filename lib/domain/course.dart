class Course {
  final int? id;
  final String code;
  final String title;
  final double credits;
  final List<double?> ctMarks;

  Course({
    this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.ctMarks,
  });

  int get maxCts => credits >= 3.0 ? 4 : 3;
  int get countedCts => credits >= 3.0 ? 3 : 2;

  Map<String, dynamic> calculateCtScore() {
    List<MapEntry<int, double>> indexedMarks = [];
    for (int i = 0; i < maxCts; i++) {
      double val = 0.0;
      if (i < ctMarks.length && ctMarks[i] != null) {
        val = ctMarks[i]!;
      }
      indexedMarks.add(MapEntry(i, val));
    }

    indexedMarks.sort((a, b) => b.value.compareTo(a.value));

    List<int> counted = [];
    List<int> discarded = [];
    double total = 0.0;

    for (int i = 0; i < indexedMarks.length; i++) {
      if (i < countedCts) {
        counted.add(indexedMarks[i].key);
        total += indexedMarks[i].value;
      } else {
        discarded.add(indexedMarks[i].key);
      }
    }

    return {
      'total': total,
      'counted': counted,
      'discarded': discarded,
    };
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'code': code,
        'title': title,
        'credits': credits,
        'ctMarks': ctMarks,
      };

  factory Course.fromJson(Map<String, dynamic> json) {
    var rawMarks = json['ctMarks'] as List<dynamic>? ?? [];
    List<double?> parsedMarks = rawMarks.map((e) => e != null ? (e as num).toDouble() : null).toList();
    return Course(
      id: json['id'] as int?,
      code: json['code'] as String,
      title: json['title'] as String,
      credits: (json['credits'] as num).toDouble(),
      ctMarks: parsedMarks,
    );
  }

  Course copyWith({
    int? id,
    String? code,
    String? title,
    double? credits,
    List<double?>? ctMarks,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      credits: credits ?? this.credits,
      ctMarks: ctMarks ?? this.ctMarks,
    );
  }
}
