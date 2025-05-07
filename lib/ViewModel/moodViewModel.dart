import 'package:flutter/foundation.dart';
import 'package:seek_here/Model/diary_entry.dart';
import 'package:seek_here/Model/mood.dart';
import 'package:seek_here/services/firebase_service.dart';
import 'package:seek_here/services/gemini_service.dart';
import 'package:seek_here/utils/logger.dart';

class MoodViewModel extends ChangeNotifier {
  final GeminiService _geminiService;
  final FirebaseService _firebaseMoodService;
  final AppLogger _logger = AppLogger();

  UserMood? _currentMood;
  DiaryEntry? _latestDiaryEntry;
  Map<String, dynamic>? _emotionAnalysis;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastMoodDate;

  MoodViewModel({
    GeminiService? geminiService,
    FirebaseService? firebaseMoodService,
  }) : _geminiService = geminiService ?? GeminiService(),
       _firebaseMoodService = firebaseMoodService ?? FirebaseService();

  UserMood? get currentMood => _currentMood;
  DiaryEntry? get latestDiaryEntry => _latestDiaryEntry;
  Map<String, dynamic>? get emotionAnalysis => _emotionAnalysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastMoodDate => _lastMoodDate;

  Future<void> fetchLatestData() async {
    // Always reset loading state at start
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.info('Starting to fetch latest mood...');

      final latestMood = await _firebaseMoodService.fetchLatestMood();
      final latestDiary = await _firebaseMoodService.fetchLatestDiary();
      _logger.info('Received mood from Firebase: ${latestMood?.toString() ?? "null"}');

      if (latestMood != null || latestDiary != null) {
        _currentMood = latestMood;
        _latestDiaryEntry = latestDiary;
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
        _logger.info('No mood record found in Firebase');
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch mood: ${e.toString()}';
      _logger.error('Error in fetchLatestMood', e);
    } finally {
      // Ensure loading is always false when complete
      _isLoading = false;
      notifyListeners();

      _logger.info('''
      Fetch completed:
      Current Mood: ${_currentMood?.toString() ?? "null"}
      Loading: $_isLoading
    ''');
    }
  }

  Future<bool> analyzeEmotion() async {
    if (_currentMood == null) {
      _logger.error('Cannot analyze emotion: no mood data available');
      _errorMessage = 'No mood data available for analysis';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _emotionAnalysis = await _geminiService.analyzeUserEmotion(
        _currentMood!,
        _latestDiaryEntry,
      );

      _logger.info('Emotion analysis completed successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Error in emotion analysis: $e');
      _isLoading = false;
      _errorMessage = 'Failed to analyze emotion: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  List<String> get videoCategories {
    if (_emotionAnalysis != null &&
        _emotionAnalysis!.containsKey('videoCategories')) {
      return List<String>.from(_emotionAnalysis!['videoCategories']);
    }
    return ['motivational', 'funny', 'relaxing']; // Default categories
  }

  List<String> get musicGenres {
    if (_emotionAnalysis != null &&
        _emotionAnalysis!.containsKey('musicGenres')) {
      return List<String>.from(_emotionAnalysis!['musicGenres']);
    }
    return ['upbeat', 'relaxing', 'popular']; // Default genres
  }

  String get recommendedMood {
    if (_emotionAnalysis != null &&
        _emotionAnalysis!.containsKey('recommendedMood')) {
      return _emotionAnalysis!['recommendedMood'] as String;
    }
    return 'positive'; // Default mood
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // This method can be called when a new mood is recorded
  Future<void> recordNewMood(UserMood mood) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Here you would save the mood to Firebase
      // await _firebaseMoodService.saveMood(mood);

      _currentMood = mood;
      _lastMoodDate = mood.timestamp;

      _logger.info('New mood recorded: ${mood.moodType}');
    } catch (e) {
      _errorMessage = 'Failed to save mood: ${e.toString()}';
      _logger.error('Error in recordNewMood', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<UserMood>> fetchAllMoods() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final moods = await _firebaseMoodService.fetchAllMoods();
      
      _isLoading = false;
      notifyListeners();
      return moods;
    } catch (e) {
      _logger.error('Error in fetchAllMoods: $e');
      _isLoading = false;
      _errorMessage = 'Failed to fetch moods: ${e.toString()}';
      notifyListeners();
      throw Exception('Failed to fetch moods: $e');
    }
  }
}

