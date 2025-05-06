// models/event.dart
import 'location.dart';

class Event {
  final String id;
  final String title;
  final String organizer;
  final Location location;
  final DateTime startDate;
  final DateTime endDate;
  final double fee;
  final String description;
  final String? imageUrl;
  final String? webUrl;
  final String? category; // Added category field
  final List<String> requirements;
  bool isFavorite;

  Event({
    required this.id,
    required this.title,
    required this.organizer,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.fee,
    required this.description,
    this.imageUrl,
    this.webUrl,
    this.category,
    this.requirements = const [],
    this.isFavorite = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      organizer: json['organizer'],
      location: Location.fromJson(json['location']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      fee: json['fee'].toDouble(),
      description: json['description'],
      imageUrl: json['imageUrl'],
      webUrl: json['webUrl'],
      category: json['category'],
      requirements: List<String>.from(json['requirements'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organizer': organizer,
      'location': location.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'fee': fee,
      'description': description,
      'imageUrl': imageUrl,
      'webUrl': webUrl,
      'category': category,
      'requirements': requirements,
      'isFavorite': isFavorite,
    };
  }
}

// Fix for createdAt - use proper ISO format
extension DateTimeExtension on DateTime {
  String toISOString() {
    return toIso8601String();
  }
}