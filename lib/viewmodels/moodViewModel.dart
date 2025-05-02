import 'package:flutter/foundation.dart';
import '../../models/mood.dart';
import '../../models/diary_entry.dart';
import '../../services/gemini_service.dart';
import '../../utils/logger.dart';

class MoodViewModel extends ChangeNotifier {
  final GeminiService _geminiService;
  final AppLogger _logger = AppLogger();
  
  UserMood? _currentMood;
  DiaryEntry? _latestDiaryEntry;
  Map<String, dynamic>? _emotionAnalysis;
  bool _isLoading = false;
  String? _errorMessage;

  MoodViewModel({
    GeminiService? geminiService,
  }) : _geminiService = geminiService ?? GeminiService();

  UserMood? get currentMood => _currentMood;
  DiaryEntry? get latestDiaryEntry => _latestDiaryEntry;
  Map<String, dynamic>? get emotionAnalysis => _emotionAnalysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> setMood(UserMood mood) async {
    _currentMood = mood;
    notifyListeners();
  }

  Future<void> setDiaryEntry(DiaryEntry diaryEntry) async {
    _latestDiaryEntry = diaryEntry;
    notifyListeners();
  }

  Future<bool> analyzeEmotion() async {
    if (_currentMood == null) {
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
}