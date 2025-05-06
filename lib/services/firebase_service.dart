import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood.dart';
import '../utils/logger.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final AppLogger _logger = AppLogger();

  FirebaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserMood?> fetchLatestMood() async {
    try {
      // Get today's date at midnight (start of day)
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);

      // Convert to Firestore Timestamp
      final Timestamp startTimestamp = Timestamp.fromDate(startOfDay);

      final QuerySnapshot snapshot = await _firestore
          .collection('moods')
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map;
        final Timestamp timestamp = data['date'] as Timestamp;

        // Convert reasons array to List for notes field
        List<String> reasonsList = [];
        if (data['reasons'] != null) {
          reasonsList = List.from(data['reasons']);
        }

        return UserMood(
          id: doc.id,
          moodType: data['mood'] ?? '',
          notes: reasonsList,
          timestamp: timestamp.toDate(),
        );
      }
      return null;
    } catch (e) {
      _logger.error('Error fetching today\'s latest mood: $e');
      throw Exception('Failed to fetch today\'s latest mood: $e');
    }
  }

  Future<List<UserMood>> fetchAllMoods() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('moods')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = data['date'] as Timestamp;

        // Convert reasons array to List<String> for notes field
        List<String> reasonsList = [];
        if (data['reasons'] != null) {
          reasonsList = List<String>.from(data['reasons']);
        }

        return UserMood(
          id: doc.id,
          moodType: data['mood'] ?? '',
          notes: reasonsList,
          timestamp: timestamp.toDate(),
        );
      }).toList();
    } catch (e) {
      _logger.error('Error fetching all moods: $e');
      throw Exception('Failed to fetch moods: $e');
    }
  }

  Future<void> saveMood(String moodType, List<String> reasons) async {
    try {
      await _firestore.collection('moods').add({
        'mood': moodType,
        'reasons': reasons,
        'date': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.error('Error saving mood: $e');
      throw Exception('Failed to save mood: $e');
    }
  }

  Future<void> updateMood(String id, String moodType, List<String> reasons) async {
    try {
      await _firestore.collection('moods').doc(id).update({
        'mood': moodType,
        'reasons': reasons,
        'date': Timestamp.now(),
      });
    } catch (e) {
      _logger.error('Error updating mood: $e');
      throw Exception('Failed to update mood: $e');
    }
  }

  Future<void> deleteMood(String id) async {
    try {
      await _firestore.collection('moods').doc(id).delete();
    } catch (e) {
      _logger.error('Error deleting mood: $e');
      throw Exception('Failed to delete mood: $e');
    }
  }
}