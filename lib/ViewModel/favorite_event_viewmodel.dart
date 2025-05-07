import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../Model/event.dart';
import '../../service/firebase_service.dart';

class FavoriteEventsViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  String? userId;
 
  List<Event> _favoriteEvents = [];
  bool _isLoading = false;
  String? _error;
 
  FavoriteEventsViewModel() {
    _initializeViewModel();
  }
  
  // Initialize in proper sequence
  Future<void> _initializeViewModel() async {
    await _fetchUserId();
    if (userId != null) {
      await _loadFavoriteEvents();
    }
  }
 
  List<Event> get favoriteEvents => _favoriteEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> _fetchUserId() async {
    try {
      _setLoading(true);
      userId = await _firebaseService.getUserID();
      debugPrint('📌 FavoriteEventsViewModel initialized with userId: $userId');
      
      if (userId == null) {
        _setError('User ID is null. User may not be logged in.');
        return;
      }
      
    } catch (e) {
      _setError('Failed to fetch user ID: $e');
    }
  }
 
  Future<void> _loadFavoriteEvents() async {
    if (userId == null) {
      await _fetchUserId();
      if (userId == null) {
        _setError('Cannot load favorites: User ID is still null');
        return;
      }
    }
    
    try {
      _setLoading(true);
      debugPrint('🔍 Loading favorite events for userId: $userId');
     
      _favoriteEvents = await _firebaseService.getFavoriteEvents(userId!);
     
      debugPrint('✅ Loaded ${_favoriteEvents.length} favorite events');
      debugPrint('Event details: ${_favoriteEvents.map((e) => e.title).toList()}');
     
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error loading favorite events: $e');
      _setError('Failed to load favorite events: $e');
    }
  }
 
  Future<void> removeFromFavorites(String eventId) async {
    if (userId == null) {
      _setError('Cannot remove favorite: User ID is null');
      return;
    }
    
    try {
      debugPrint('🗑️ Removing event $eventId from favorites');
      await _firebaseService.removeFavoriteEvent(userId!, eventId);
      
      // Update local list after successful removal
      _favoriteEvents.removeWhere((event) => event.id == eventId);
      notifyListeners();
      
      debugPrint('✅ Successfully removed event from favorites');
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
  
  /*
  Future<void> undoRemoveFavorite(Event event) async {
    if (userId == null) {
      _setError('Cannot restore favorite: User ID is null');
      return;
    }
    
    try {
      debugPrint('↩️ Undoing removal of event ${event.id} from favorites');
      _setLoading(true);
     
      // Add back to Firebase
      await _firebaseService.addFavoriteEvent(userId!, event);
     
      // Update local list
      if (!_favoriteEvents.any((e) => e.id == event.id)) {
        _favoriteEvents.add(event);
        notifyListeners();
      }
     
      _setLoading(false);
      debugPrint('✅ Successfully restored event to favorites');
    } catch (e) {
      debugPrint('❌ Error undoing removal from favorites: $e');
      _setError('Failed to restore favorite: $e');
    }
  }
 */

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