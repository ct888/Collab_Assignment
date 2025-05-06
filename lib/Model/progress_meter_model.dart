// Combined model file for Progress Meter related data structures
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// MoodData class for managing mood statistics
class MoodData {
  final String name;
  final int count;
  double percentage = 0.0;

  MoodData({
    required this.name,
    required this.count
  });

  static List<MoodData> createWithPercentages(List<MoodData> moods) {
    int totalCount = moods.fold(0, (sum, mood) => sum + mood.count);

    return moods.map((mood) {
      double percentage = totalCount > 0 ? mood.count / totalCount : 0.0;
      return MoodData(
        name: mood.name,
        count: mood.count
      )..percentage = percentage;
    }).toList();
  }
}

// InteractionData class for managing interaction statistics
class InteractionData {
  final String name;
  final int points;
  double percentage = 0.0;

  InteractionData({
    required this.name,
    required this.points
  });

  static List<InteractionData> createWithPercentages(List<InteractionData> interactions) {
    int totalPoints = interactions.fold(0, (sum, interaction) => sum + interaction.points);

    return interactions.map((interaction) {
      double percentage = totalPoints > 0 ? interaction.points / totalPoints : 0.0;
      return InteractionData(
        name: interaction.name,
        points: interaction.points
      )..percentage = percentage;
    }).toList();
  }
}

// RecordEntry class for storing user records
class RecordEntry {
  final DateTime timestamp;
  final String recordType; // 'mood', 'journal', 'meditation', etc.
  final Map<String, dynamic> data; // Flexible data structure to store different record types

  RecordEntry({
    required this.timestamp,
    required this.recordType,
    required this.data,
  });

  // Convert a record entry to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'recordType': recordType,
      'data': data,
    };
  }

  // Create a record entry from a map
  factory RecordEntry.fromMap(Map<String, dynamic> map) {
    return RecordEntry(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      recordType: map['recordType'],
      data: map['data'],
    );
  }

  // Get points value based on record type
  static int getPointsForType(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'mood':
        return 10;
      case 'quote':
        return 5;
      case 'diary':
        return 10;
      case 'recommender':
        return 5;
      default:
        return 5;
    }
  }
  
  // Factory to create from Firestore data
  factory RecordEntry.fromFirestore(DocumentSnapshot doc, String type) {
    Map<String, dynamic> docData = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle timestamp that might be null - check various field names
    final timestamp = docData['date'];
    final DateTime date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.now(); // Fallback to current time
    
    return RecordEntry(
      timestamp: date,
      recordType: type,
      data: docData,
    );
  }
  
  // Convert to activity-like display
  UserActivity toActivity() {
    String activityText;
    
    // Set the activity text based on record type
    switch (recordType) {
      case 'mood':
        activityText = "Recorded Mood";
        break;
      case 'quote':
        activityText = "Requested Quote";
        break;
      case 'diary':
        activityText = "Wrote Diary";
        break;
      case 'recommender':
        activityText = "Requested Recommender";
        break;
      default:
        activityText = "Unknown Activity";
    }
    
    // Get points from the static map
    int points = getPointsForType(recordType);
    
    return UserActivity(
      activity: activityText,
      timestamp: timestamp,
      pointsAdded: points,
    );
  }

  // Method to insert timestamp data into specified Firebase collection
  static Future<void> insertTimestampToCollection(String tableName) async {
    try {
      // Get the current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }
      
      final data = {
        'date': Timestamp.now(),
      };
      
      // Insert into the specified collection under the user's document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection(tableName)
          .add(data);
    } catch (e) {
      debugPrint('Error inserting timestamp: $e');
    }
  }
}

// UserActivity class for tracking user interactions and points
class UserActivity {
  final String activity;
  final DateTime timestamp;
  final int pointsAdded;

  UserActivity({
    required this.activity,
    required this.timestamp,
    required this.pointsAdded,
  });

  // Convert an activity to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'pointsAdded': pointsAdded,
    };
  }

  // Create an activity from a map
  factory UserActivity.fromMap(Map<String, dynamic> map) {
    return UserActivity(
      activity: map['activity'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      pointsAdded: map['pointsAdded'],
    );
  }

  // Sort activities by timestamp (newest first)
  static List<UserActivity> sortByTimestamp(List<UserActivity> activities) {
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }

  // Factory to create from Firestore data with better error handling
  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle timestamp that might be null (still processing on server)
    final timestamp = data['timestamp'];
    final DateTime date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.now(); // Fallback to current time
    
    return UserActivity(
      activity: data['activity'] ?? 'Unknown activity',
      timestamp: date,
      pointsAdded: (data['pointsAdded'] ?? 0),
    );
  }

  // Static helper to standardize activity names
  static String standardizeActivityName(String activity) {
    activity = activity.toLowerCase();
    
    if (activity.contains('quote')) {
      return 'Requested Quote';
    } else if (activity.contains('recommend')) {
      return 'Requested Recommender';
    } else if (activity.contains('diary')) {
      return 'Wrote Diary';
    } else if (activity.contains('mood')) {
      return 'Recorded Mood';
    } else {
      return activity;
    }
  }

  // Create a standardized activity
  static UserActivity createStandardized(String rawActivity, DateTime timestamp, int pointsAdded) {
    return UserActivity(
      activity: standardizeActivityName(rawActivity),
      timestamp: timestamp,
      pointsAdded: pointsAdded
    );
  }
}

// Static data for application
class ProgressMeterData {
  // List of motivational prompts
  static final List<String> motivationalPrompts = [
    'Keep going! You can do it!',
    'You\'re making great progress!',
    'Every step counts, keep moving forward!',
    'Believe in yourself, you\'re amazing!',
    'Small steps lead to big changes!',
    'Your journey matters, stay focused!',
    'You\'re stronger than you think!',
    'Progress over perfection!',
    'Today is a new opportunity!',
    'One day at a time, you got this!',
    'Stay positive, stay motivated!',
    'You are capable of amazing things!',
    'Keep pushing, you\'re almost there!',
    'Success is a journey, not a destination!',
    'Every effort counts, keep it up!',
    'You are on the right track!',
    'Your hard work will pay off!',
    'Stay committed to your goals!',
    'You are making a difference!',
    'Keep striving for greatness!'
  ];
}
