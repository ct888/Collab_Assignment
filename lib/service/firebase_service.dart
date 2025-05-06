import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../Model/saved_place.dart';
import '../Model/event.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Saved Places
  Future<List<SavedPlace>> getSavedPlaces(String userId) async {
    final querySnapshot = await _firestore
        .collection('saved_places')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SavedPlace.fromJson(data);
    }).toList();
  }
  
  Future<void> savePlace(SavedPlace place) async {
    await _firestore.collection('saved_places').doc(place.id).set(place.toJson());
  }
  
  Future<void> deletePlace(String placeId) async {
    await _firestore.collection('saved_places').doc(placeId).delete();
  }
  
  // UPDATED: Favorite Events with debugging
  Future<List<Event>> getFavoriteEvents(String userId) async {
    debugPrint('🔍 FirebaseService: Fetching favorite events for userId: $userId');
    
    try {
      final querySnapshot = await _firestore
          .collection('favorite_events')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('📊 FirebaseService: Found ${querySnapshot.docs.length} documents');
      
      // Debug: Print all document IDs
      for (var doc in querySnapshot.docs) {
        debugPrint('📄 Document ID: ${doc.id}');
      }
      
      // If no documents found, add a more descriptive debug message
      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ No documents found with userId: $userId in favorite_events collection');
        // Optional: Print a raw query to check directly in Firestore console
        debugPrint('💡 Check Firestore query: collection("favorite_events").where("userId", "==", "$userId")');
        return [];
      }
      
      List<Event> events = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          
          // Debug: Print document structure
          debugPrint('🔍 Document data structure: ${data.keys.toList()}');
          
          // Check for 'event' field existence
          if (!data.containsKey('event')) {
            debugPrint('⚠️ Document ${doc.id} is missing "event" field. Available fields: ${data.keys.toList()}');
            continue;
          }
          
          final eventData = data['event'];
          debugPrint('📝 Event data type: ${eventData.runtimeType}');
          
          // Additional validation
          if (eventData is! Map) {
            debugPrint('⚠️ Event data is not a Map: $eventData');
            continue;
          }
          
          final event = Event.fromJson(eventData as Map<String, dynamic>);
          event.isFavorite = true;
          events.add(event);
          debugPrint('✅ Successfully processed event: ${event.title}');
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing document: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
      
      debugPrint('📊 FirebaseService: Returning ${events.length} events');
      return events;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching favorite events: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Rethrow to handle in the view model
    }
  }
  
  Future<void> addFavoriteEvent(String userId, Event event) async {
    debugPrint('➕ Adding event to favorites: ${event.id} for user: $userId');
    
    try {
      // First check if the event is already favorited
      final existingQuery = await _firestore
          .collection('favorite_events')
          .where('userId', isEqualTo: userId)
          .where('event.id', isEqualTo: event.id)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        debugPrint('ℹ️ Event already in favorites');
        return;
      }
      
      // Add to favorites
      await _firestore.collection('favorite_events').add({
        'userId': userId,
        'event': event.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Event successfully added to favorites');
    } catch (e) {
      debugPrint('❌ Error adding to favorites: $e');
      rethrow;
    }
  }
  
  Future<void> removeFavoriteEvent(String userId, String eventId) async {
    debugPrint('🗑️ Removing event from favorites: $eventId for user: $userId');
    
    try {
      final querySnapshot = await _firestore
          .collection('favorite_events')
          .where('userId', isEqualTo: userId)
          .where('event.id', isEqualTo: eventId)
          .get();
      
      debugPrint('🔍 Found ${querySnapshot.docs.length} documents to delete');
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        debugPrint('✅ Deleted document: ${doc.id}');
      }
    } catch (e) {
      debugPrint('❌ Error removing from favorites: $e');
      rethrow;
    }
  }
}