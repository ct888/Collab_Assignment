import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _shouldNavigateBack = false;
  bool _shouldShowErrorSnackbar = false;
 
  EventListViewModel({required this.userId});
 
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get shouldNavigateBack => _shouldNavigateBack;
  bool get shouldShowErrorSnackbar => _shouldShowErrorSnackbar;

  // Call this after showing the snackbar to reset the flag
  void errorSnackbarShown() {
    _shouldShowErrorSnackbar = false;
    notifyListeners();
  }

  // Call this after navigating back
  void navigationHandled() {
    _shouldNavigateBack = false;
    notifyListeners();
  }
 
  Future<void> fetchEvents(Location location) async {
    try {
      _setLoading(true);
      _error = null;
      _shouldNavigateBack = false;
      _shouldShowErrorSnackbar = false;
      
      _events = await _geminiService.getNearbyEvents(location);
     
      // Check which events are favorites
      final favoriteEvents = await _firebaseService.getFavoriteEvents(userId);
      for (var event in _events) {
        event.isFavorite = favoriteEvents.any((favEvent) => favEvent.id == event.id);
      }
     
      _setLoading(false);
    } catch (e) {
      _handleError('Failed to fetch events: $e', shouldNavigate: true);
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
      // We don't need to navigate back for this error
      _handleError('Error updating favorites: $e', shouldNavigate: false);
    }
  }
 
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
 
  void _handleError(String errorMessage, {bool shouldNavigate = false}) {
    print('Error in EventListViewModel: $errorMessage');
    _error = _getUserFriendlyErrorMessage(errorMessage);
    _isLoading = false;
    _shouldShowErrorSnackbar = true;
    
    if (shouldNavigate) {
      _shouldNavigateBack = true;
    }
    
    notifyListeners();
  }

  String _getUserFriendlyErrorMessage(String technicalError) {
    // Convert technical error messages to user-friendly messages
    if (technicalError.contains('Failed to parse events from Gemini response') ||
        technicalError.contains('Error parsing JSON')) {
      return 'Unable to fetch events data. The service is currently unavailable.';
    } else if (technicalError.contains('Failed to get events from Gemini API')) {
      return 'Unable to connect to the events service. Please check your internet connection.';
    } else if (technicalError.contains('timeout')) {
      return 'The request timed out. Please try again later.';
    } else {
      return 'An error occurred while fetching events. Please try again.';
    }
  }
 
  void clearError() {
    _error = null;
    _shouldShowErrorSnackbar = false;
    notifyListeners();
  }
}