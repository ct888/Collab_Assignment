import 'package:cloud_firestore/cloud_firestore.dart';


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
      'id': id,
      'date': Timestamp.fromDate(date),
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

  factory DiaryEntry.fromMap(Map<String, dynamic> map, {String? docId}) {
    return DiaryEntry(
      id: docId ?? map['id'] ?? '',
    date: (map['date'] as Timestamp).toDate(), // Convert back from Timestamp
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      publicVisibility: map['publicVisibility'] ?? false,
      dataTracking: map['dataTracking'] ?? false,
      isDraft: map['isDraft'] ?? false,
      userId: map['userId'] ?? '',
      likedUsers: List<String>.from(map['likedUsers'] ?? []),
      likes: map['likes'] ?? 0,
    );
  }
}


