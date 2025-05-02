class UserMood {
  final String id;
  final String moodType; // happy, sad, anxious, relaxed, energetic, etc.
  final int intensity; // 1-10
  final String notes;
  final DateTime timestamp;

  UserMood({
    required this.id,
    required this.moodType,
    required this.intensity,
    required this.notes,
    required this.timestamp,
  });

  factory UserMood.fromJson(Map<String, dynamic> json) {
    return UserMood(
      id: json['id'] ?? '',
      moodType: json['moodType'] ?? '',
      intensity: json['intensity'] ?? 5,
      notes: json['notes'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodType': moodType,
      'intensity': intensity,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}