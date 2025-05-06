// view_models/event_recommender_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../Model/location.dart';
import '../../Model/saved_place.dart';
import '../../service/location_service.dart';
import '../../service/firebase_service.dart';

class EventRecommenderViewModel with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();
  final String userId;
 
  Location? _currentLocation;
  List<SavedPlace> _savedPlaces = [];
  bool _isLoading = false;
  String? _error;
 
  EventRecommenderViewModel({required this.userId}) {
    _initializeLocation();
    _loadSavedPlaces();
  }
 
  Location? get currentLocation => _currentLocation;
  List<SavedPlace> get savedPlaces => _savedPlaces;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _shouldShowErrorSnackbar = false;
  bool get shouldShowErrorSnackbar => _shouldShowErrorSnackbar;
  
    void errorSnackbarShown() {
    _shouldShowErrorSnackbar = false;
  }

    void _setUserFriendlyError(String technicalError) {
    // Map common error patterns to user-friendly messages
    if (technicalError.contains('Could not find location')) {
      _error = 'Could not find location for this address. Please try again with a more specific address.';
    } else if (technicalError.contains('Permission denied')) {
      _error = 'Location permission denied. Please enable location access in your device settings.';
    } else if (technicalError.contains('Network')) {
      _error = 'Network error. Please check your internet connection and try again.';
    } else if (technicalError.contains('Timeout')) {
      _error = 'Request timed out. Please try again later.';
    } else {
      // Generic user-friendly message for other errors
      _error = 'Something went wrong. Please try again later.';
    }
        // Log the technical error for debugging
    print('Technical error: $technicalError');
    
    _isLoading = false;
    _shouldShowErrorSnackbar = true;
    notifyListeners();
  }
 
  Future<void> _initializeLocation() async {
    try {
      _setLoading(true);
      _currentLocation = await _locationService.getCurrentLocation();
      _setLoading(false);
    } catch (e) {
      _setUserFriendlyError('Could not get current location: $e');
    }
  }
 
  Future<void> _loadSavedPlaces() async {
    try {
      _setLoading(true);
      _savedPlaces = await _firebaseService.getSavedPlaces(userId);
      _setLoading(false);
    } catch (e) {
      _setUserFriendlyError('Failed to load saved places: $e');
    }
  }
 
  Future<void> updateLocationByAddress(String address) async {
    try {
      debugPrint('9');
      _setLoading(true);
      _currentLocation = await _locationService.getLocationFromAddress(address);
      _error = null; 
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('8');
       _setUserFriendlyError('Could not find location for this address: $e');
    }
  }


 
  Future<void> updateLocationByCoordinates(LatLng position) async {
    try {
      _setLoading(true);
      String? address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude
      );
     
      _currentLocation = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
      _error = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setUserFriendlyError('Could not update location: $e');
    }
  }
 
  Future<void> saveCurrentPlace(String name) async {
    if (_currentLocation == null) {
      _setUserFriendlyError('No location available to save');
      return;
    }
   
    try {
      final savedPlace = SavedPlace(
        id: const Uuid().v4(),
        name: name,
        location: _currentLocation!,
        userId: userId,
        createdAt: DateTime.now(),
      );
     
      await _firebaseService.savePlace(savedPlace);
      _savedPlaces.add(savedPlace);
      notifyListeners();
    } catch (e) {
      _setUserFriendlyError('Failed to save place: $e');
    }
  }
 
  Future<void> deleteSavedPlace(String placeId) async {
    try {
      await _firebaseService.deletePlace(placeId);
      _savedPlaces.removeWhere((place) => place.id == placeId);
      notifyListeners();
    } catch (e) {
      _setUserFriendlyError('Failed to delete place: $e');
    }
  }

  Future<void> refreshCurrentLocation() async {
  try {
    _setLoading(true);
    _currentLocation = await _locationService.getCurrentLocation();
    _error = null;
    _setLoading(false);
  } catch (e) {
    _setUserFriendlyError('Could not get current location: $e');
  }
}
 
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
 
  void clearError() {
    _error = null;
    notifyListeners();
  }
}