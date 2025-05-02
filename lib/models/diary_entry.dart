class DiaryEntry {
  final String id;
  final String content;
  final DateTime timestamp;
  final List<String> tags;

  DiaryEntry({
    required this.id,
    required this.content,
    required this.timestamp,
    this.tags = const [],
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'tags': tags,
    };
  }
}