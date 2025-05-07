// view_models/event_detail_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../Model/event.dart';
import '../../service/firebase_service.dart';

class EventDetailViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  String? _userId;
  final Event event;

  bool _isLoading = false;
  String? _error;

  EventDetailViewModel({
    required this.event,
  }) {
    _fetchUserId(); // Call the function to get the userId when the ViewModel is created
  }

  String? get userId => _userId; // Getter for userId
  Event get currentEvent => event;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _fetchUserId() async {
    try {
      _setLoading(true);
      _userId = await _firebaseService.getUserID();
      _setLoading(false);
      notifyListeners(); // Notify listeners when userId is fetched
    } catch (e) {
      _setError('Failed to fetch user ID: $e');
    }
  }

  Future<void> toggleFavorite() async {
    if (_userId == null) {
      _setError('User ID not available. Please try again.');
      return;
    }
    try {
      _setLoading(true);

      if (event.isFavorite) {
        await _firebaseService.removeFavoriteEvent(_userId!, event.id); // Use the fetched userId
        event.isFavorite = false;
      } else {
        await _firebaseService.addFavoriteEvent(_userId!, event); // Use the fetched userId
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