class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
  final String? imageUrl;
  final bool publicVisibility;
  final bool dataTracking;
  final bool isDraft;
  final String userId;
  List<String> likedUsers;
  int likes;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.imageUrl,
    this.publicVisibility = false,
    this.dataTracking = false,
    this.isDraft = false,
    required this.userId,
    required this.likedUsers,
    this.likes = 0, 
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'content': content,
      'imageUrl': imageUrl,
      'publicVisibility': publicVisibility,
      'dataTracking': dataTracking,
      'isDraft': isDraft,
      'userId': userId,
      'likes': likes,
      'likedUsers': likedUsers,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '', // 避免 null 错误
      date: DateTime.parse(map['date']),
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'], // 不用 ?? '', 因为 imageUrl 是可空
      publicVisibility: map['publicVisibility'] ?? false,
      dataTracking: map['dataTracking'] ?? false,
      isDraft: map['isDraft'] ?? false,
      userId: map['userId'] ?? '',
      likedUsers: List<String>.from(map['likedUsers'] ?? []),
      likes: map['likes'] ?? 0,
    );
  }
}
