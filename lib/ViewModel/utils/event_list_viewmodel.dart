import 'package:flutter/foundation.dart';
import '../../Model/event.dart';
import '../../Model/location.dart';
import '../../service/gemini_service.dart';
import '../../service/firebase_service.dart';

class EventListViewModel with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();
  final String userId;
  
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;
  
  EventListViewModel({required this.userId});
  
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchEvents(Location location) async {
    try {
      _setLoading(true);
      _events = await _geminiService.getNearbyEvents(location);
      
      // Check which events are favorites
      final favoriteEvents = await _firebaseService.getFavoriteEvents(userId);
      for (var event in _events) {
        event.isFavorite = favoriteEvents.any((favEvent) => favEvent.id == event.id);
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch events: $e');
    }
  }
  
  // Add this new method to update a single event's favorite status
  Future<void> updateEventFavoriteStatus(String eventId) async {
    try {
      final favoriteEvents = await _firebaseService.getFavoriteEvents(userId);
      final index = _events.indexWhere((event) => event.id == eventId);
      
      if (index != -1) {
        _events[index].isFavorite = favoriteEvents.any((favEvent) => favEvent.id == eventId);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating event favorite status: $e');
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