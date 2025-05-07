import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../Model/event.dart';
import '../../Model/location.dart';
import '../../service/gemini_service.dart';
import '../../service/firebase_service.dart';
import 'package:seek_here/utils/logger.dart';
import 'package:seek_here/Model/diary_entry.dart';
import 'package:seek_here/Model/mood.dart';

class EventListViewModel with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();
  
  String? userId;
  final AppLogger _logger = AppLogger();
 
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;
  bool _shouldNavigateBack = false;
  bool _shouldShowErrorSnackbar = false;
  
  // Add new properties for mood and diary data
  UserMood? _currentMood;
  DiaryEntry? _latestDiaryEntry;
  DateTime? _lastMoodDate;
  
  // Getters for new properties
  UserMood? get currentMood => _currentMood;
  DiaryEntry? get latestDiaryEntry => _latestDiaryEntry;
  DateTime? get lastMoodDate => _lastMoodDate;
 
  EventListViewModel(){
    _fetchUserId();
  }
 
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get shouldNavigateBack => _shouldNavigateBack;
  bool get shouldShowErrorSnackbar => _shouldShowErrorSnackbar;

  Future<void> _fetchUserId() async {
    try {
      _setLoading(true);
      userId = await _firebaseService.getUserID();
      _setLoading(false);
      notifyListeners(); // Notify listeners when userId is fetched
      
      // Once we have the userId, fetch the latest mood and diary data
      if (userId != null && userId!.isNotEmpty) {
        await fetchLatestData();
      }
    } catch (e) {
      _setError('Failed to fetch user ID: $e');
    }
  }

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

  Future<void> fetchLatestData() async {
    // Always reset loading state at start
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.info('Starting to fetch latest mood and diary data...');

      final latestMood = await _firebaseService.fetchLatestMood();
      final latestDiary = await _firebaseService.fetchLatestDiary();
      _logger.info('Received mood from Firebase: ${latestMood?.toString() ?? "null"}');

      if (latestMood != null || latestDiary != null) {
        _currentMood = latestMood;
        _latestDiaryEntry = latestDiary;
        if (latestMood != null) {
          _lastMoodDate = latestMood.timestamp;
        }
        
        _logger.info('''
    Mood Details:
    Type: ${_currentMood?.moodType}
    Notes: ${_currentMood?.notes.join(', ')}
    Date: ${_currentMood?.timestamp}
    Diary Details:
    Content: ${_latestDiaryEntry?.content}
  ''');
      } else {
        _currentMood = null;
        _latestDiaryEntry = null;
        _lastMoodDate = null;
        _logger.info('No mood or diary record found in Firebase');
      }
    } catch (e) {
      _error = 'Failed to fetch mood and diary data: ${e.toString()}';
      _logger.error('Error in fetchLatestData', e);
    } finally {
      // Ensure loading is always false when complete
      _isLoading = false;
      notifyListeners();

      _logger.info('''
      Fetch completed:
      Current Mood: ${_currentMood?.toString() ?? "null"}
      Current Diary: ${_latestDiaryEntry?.content ?? "null"}
      Loading: $_isLoading
    ''');
    }
  }
 
  Future<void> fetchEvents(Location location) async {
    try {
      _setLoading(true);
      _error = null;
      _shouldNavigateBack = false;
      _shouldShowErrorSnackbar = false;
      
      // Make sure we have the latest mood and diary data
      //if (_currentMood == null && _latestDiaryEntry == null) {
      //  await fetchLatestData();
     // }
      
      // Get events with personalized recommendations if mood data is available
      if (_currentMood != null || _latestDiaryEntry != null) {
        _events = await _geminiService.getPersonalizedEvents(
          location, 
          _currentMood, 
          _latestDiaryEntry
        );
      } else {
        // Fallback to regular events if no mood/diary data
        _events = await _geminiService.getNearbyEvents(location);
      }
     
      // Check which events are favorites
      if (userId != null && userId!.isNotEmpty) {
        final favoriteEvents = await _firebaseService.getFavoriteEvents(userId!);
        for (var event in _events) {
          event.isFavorite = favoriteEvents.any((favEvent) => favEvent.id == event.id);
        }
      }
     
      _setLoading(false);
    } catch (e) {
      _handleError('Failed to fetch events: $e', shouldNavigate: true);
    }
  }
 
  // Add this new method to update a single event's favorite status
  Future<void> updateEventFavoriteStatus(String eventId) async {
    try {
      if (userId == null || userId!.isEmpty) {
        _logger.warning('Cannot update favorite status: User ID is null or empty');
        return;
      }
      
      final favoriteEvents = await _firebaseService.getFavoriteEvents(userId!);
      final index = _events.indexWhere((event) => event.id == eventId);
     
      if (index != -1) {
        _events[index].isFavorite = favoriteEvents.any((favEvent) => favEvent.id == eventId);
        notifyListeners();
      }
    } catch (e) {
      _logger.error('Error updating event favorite status: $e');
      // We don't need to navigate back for this error
      _handleError('Error updating favorites: $e', shouldNavigate: false);
    }
  }
 
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
 
  void _handleError(String errorMessage, {bool shouldNavigate = false}) {
    _logger.error('Error in EventListViewModel: $errorMessage');
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

  void _setError(String? errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }
}