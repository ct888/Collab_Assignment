// models/saved_place.dart
import 'location.dart';

class SavedPlace {
  final String id;
  final String name;
  final Location location;
  final String userId;
  final DateTime createdAt;

  SavedPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.userId,
    required this.createdAt,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location.toJson(),
      'userId': userId,
      'createdAt': createdAt.toISOString(),
    };
  }
}

// Fix for createdAt - use proper ISO format
extension DateTimeExtension on DateTime {
  String toISOString() {
    return toIso8601String();
  }
}