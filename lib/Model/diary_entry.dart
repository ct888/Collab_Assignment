import 'package:cloud_firestore/cloud_firestore.dart';


class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
<<<<<<< HEAD
  final String? imageUrl;
  final bool publicVisibility;
  final bool dataTracking;
  final bool isDraft;
  final String userId;
  List<String> likedUsers;
  int likes;
=======
  final DateTime timestamp;
  final bool dataTracking;
  final bool isDraft;
  final String userID;
>>>>>>> main

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
<<<<<<< HEAD
    this.imageUrl,
    this.publicVisibility = false,
    this.dataTracking = false,
    this.isDraft = false,
    required this.userId,
    required this.likedUsers,
    this.likes = 0, 
  });

  Map<String, dynamic> toMap() {
=======
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
>>>>>>> main
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'content': content,
<<<<<<< HEAD
      'imageUrl': imageUrl,
      'publicVisibility': publicVisibility,
      'dataTracking': dataTracking,
      'isDraft': isDraft,
      'userId': userId,
      'likes': likes,
      'likedUsers': likedUsers,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
=======
      'timestamp': timestamp.toIso8601String(),
      'dataTracking': dataTracking,
      'isDraft': isDraft,
      'userID': userID,
>>>>>>> main
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


