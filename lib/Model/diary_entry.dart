class DiaryEntry {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool dataTracking;
  final bool isDraft;
  final String userID;

  DiaryEntry({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.dataTracking,
    required this.isDraft,
    required this.userID,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      dataTracking: json['dataTracking'] ?? false,
      isDraft: json['isDraft'] ?? false,
      userID: json['userID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'dataTracking': dataTracking,
      'isDraft': isDraft,
      'userID': userID,
    };
  }
}