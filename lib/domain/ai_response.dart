class AiResponse {
  final String topic;
  final String content;
  final String academicDefinition;
  final String simpleDefinition;
  final String examStandardDescription;
  final List<List<String>> tableData;
  final List<String> flowchartSteps;

  AiResponse({
    required this.topic,
    this.content = '',
    this.academicDefinition = '',
    this.simpleDefinition = '',
    this.examStandardDescription = '',
    this.tableData = const [],
    this.flowchartSteps = const [],
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    var rawTable = json['tableData'] as List?;
    List<List<String>> parsedTable = [];
    if (rawTable != null) {
      for (var row in rawTable) {
        if (row is List) {
          parsedTable.add(row.map((e) => e.toString()).toList());
        }
      }
    }

    var rawSteps = json['flowchartSteps'] as List?;
    List<String> parsedSteps = rawSteps != null
        ? rawSteps.map((e) => e.toString()).toList()
        : const [];

    return AiResponse(
      topic: json['topic'] ?? '',
      content: json['content'] ?? '',
      academicDefinition: json['academicDefinition'] ?? '',
      simpleDefinition: json['simpleDefinition'] ?? '',
      examStandardDescription: json['examStandardDescription'] ?? '',
      tableData: parsedTable,
      flowchartSteps: parsedSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'content': content,
      'academicDefinition': academicDefinition,
      'simpleDefinition': simpleDefinition,
      'examStandardDescription': examStandardDescription,
      'tableData': tableData,
      'flowchartSteps': flowchartSteps,
    };
  }
}
