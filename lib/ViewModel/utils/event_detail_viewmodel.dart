// view_models/event_detail_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../Model/event.dart';
import '../../service/firebase_service.dart';

class EventDetailViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final String userId;
  final Event event;
  
  bool _isLoading = false;
  String? _error;
  
  EventDetailViewModel({
    required this.userId,
    required this.event,
  });
  
  Event get currentEvent => event;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> toggleFavorite() async {
    try {
      _setLoading(true);
      
      if (event.isFavorite) {
        await _firebaseService.removeFavoriteEvent(userId, event.id);
        event.isFavorite = false;
      } else {
        await _firebaseService.addFavoriteEvent(userId, event);
        event.isFavorite = true;
      }
      
      _setLoading(false);
      notifyListeners(); // Make sure UI updates after toggling
    } catch (e) {
      _setError('Failed to update favorite status: $e');
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