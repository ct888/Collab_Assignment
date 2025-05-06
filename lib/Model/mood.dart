class UserMood {
  final String id;
  final String moodType; // happy, sad, anxious, relaxed, energetic, etc.
  final List<String> notes;
  final DateTime timestamp;
  final String userID;

  UserMood({
    required this.id,
    required this.moodType,
    required this.notes,
    required this.timestamp,
    required this.userID,
  });

  factory UserMood.fromJson(Map<String, dynamic> json) {
    return UserMood(
      id: json['id'] ?? '',
      moodType: json['moodType'] ?? '',
      notes: json['notes'] != null
          ? List<String>.from(json['notes'])
          : <String>[],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      userID: json['userID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodType': moodType,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'userID': userID,
    };
  }
}