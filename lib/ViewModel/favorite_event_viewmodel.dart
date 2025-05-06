// UPDATED: favorite_events_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../Model/event.dart';
import '../../service/firebase_service.dart';

class FavoriteEventsViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final String userId;
  
  List<Event> _favoriteEvents = [];
  bool _isLoading = false;
  String? _error;
  
  FavoriteEventsViewModel({required this.userId}) {
    debugPrint('📌 FavoriteEventsViewModel initialized with userId: $userId');
    _loadFavoriteEvents();
  }
  
  List<Event> get favoriteEvents => _favoriteEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> _loadFavoriteEvents() async {
    try {
      _setLoading(true);
      debugPrint('🔍 Loading favorite events for userId: $userId');
      
      _favoriteEvents = await _firebaseService.getFavoriteEvents(userId);
      
      debugPrint('✅ Loaded ${_favoriteEvents.length} favorite events');
      debugPrint('Event details: ${_favoriteEvents.map((e) => e.title).toList()}');
      
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error loading favorite events: $e');
      _setError('Failed to load favorite events: $e');
    }
  }
  
  Future<void> removeFromFavorites(String eventId) async {
    try {
      debugPrint('🗑️ Removing event $eventId from favorites');
      _setLoading(true);
      await _firebaseService.removeFavoriteEvent(userId, eventId);
      _favoriteEvents.removeWhere((event) => event.id == eventId);
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error removing from favorites: $e');
      _setError('Failed to remove from favorites: $e');
    }
  }
  
  Future<void> refreshFavorites() async {
    debugPrint('🔄 Refreshing favorite events');
    _error = null; // Clear previous errors
    await _loadFavoriteEvents();
  }

  // Add a new method to re-add a removed event to favorites
Future<void> undoRemoveFavorite(Event event) async {
  try {
    debugPrint('↩️ Undoing removal of event ${event.id} from favorites');
    _setLoading(true);
    
    // Add back to Firebase
    await _firebaseService.addFavoriteEvent(userId, event);
    
    // Update local list
    if (!_favoriteEvents.any((e) => e.id == event.id)) {
      _favoriteEvents.add(event);
    }
    
    _setLoading(false);
  } catch (e) {
    debugPrint('❌ Error undoing removal from favorites: $e');
    _setError('Failed to restore favorite: $e');
  }
}
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}