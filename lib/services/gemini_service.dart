import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:seek_here/Model/diary_entry.dart';
import 'package:seek_here/Model/mood.dart';
import '../Model/constants/api_constants.dart';
import '../utils/logger.dart';
import 'dart:convert';

class GeminiService {
  final GenerativeModel _model;
  final AppLogger _logger = AppLogger();

  GeminiService()
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash-preview-04-17',    // gemini-1.5-pro
        apiKey: ApiConstants.geminiApiKey,
      );

  Future<Map<String, dynamic>> analyzeUserEmotion(
    UserMood mood,
    DiaryEntry? diaryEntry,
  ) async {
    try {
      String prompt = _buildEmotionAnalysisPromptConstrained(mood, diaryEntry);
      final content = [Content.text(prompt)];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      _logger.info('Raw Gemini response: $responseText');
      if (responseText == null) {
        throw Exception('Empty response from Gemini API');
      }

      return _parseGeminiResponse(responseText);
    } catch (e) {
      _logger.error('Error analyzing emotion: $e');
      throw Exception('Failed to analyze emotion: $e');
    }
  }

  String _buildEmotionAnalysisPromptConstrained(
      UserMood mood,
      DiaryEntry? diaryEntry,
      ) {
    String diaryText =
    diaryEntry != null
        ? "The user's diary entry: ${diaryEntry.content}"
        : "No diary entry available.";

    // Format the array of notes into a readable string
    String reasonsText = "";
    if (mood.notes.isNotEmpty) {
      reasonsText = mood.notes.map((reason) => "- $reason").join("\n");
    } else {
      reasonsText = "No specific reasons provided.";
    }

    return '''
Analyze the user's emotional state based on their mood details and diary entry. Handle non-standard or unexpected mood entries (e.g., food names like "nasi lemak") by interpreting the underlying sentiment using NLP. Provide actionable recommendations for video and music content that either elevate a negative mood, sustain a positive one, or align with the sentiment inferred from diary text.

1. Analyze the mood using sentiment detection, even if the mood is a non-emotion word.
2. Extract emotional keywords from both reasons and diary text for deeper context.
3. Based on the analysis, suggest specific video and music recommendations.
4. For negative or unclear moods, recommend uplifting content.
5. For positive moods, recommend reinforcing or relaxing content.

User's mood: ${mood.moodType}  
User's reasons about their mood:  
$reasonsText  
$diaryText

Output JSON format:
{
  "emotionalState": "brief analysis",
  "contentGoal": "brief description of what content should accomplish",
  "videoCategories": ["specific video search term 1", "specific video search term 2", "specific video search term 3", ...],
  "musicGenres": ["descriptive music genre/mood 1", "descriptive music genre/mood 2", "descriptive music genre/mood 3", ...],
  "recommendedMood": "target mood"
}

Only return the JSON result. Ensure all videoCategories and musicGenres are clear, API-searchable, and emotionally relevant.
''';
  }

  Map<String, dynamic> _parseGeminiResponse(String responseText) {
    try {
      // Extract the JSON part from the response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        throw Exception('Could not extract valid JSON from Gemini response');
      }

      final jsonString = responseText.substring(jsonStart, jsonEnd);

      // Parse the JSON response
      final Map<String, dynamic> parsedJson = Map<String, dynamic>.from(
        Map<String, dynamic>.from(jsonDecode(jsonString)),
      );

      // Validate expected keys
      final requiredKeys = [
        'emotionalState',
        'contentGoal',
        'videoCategories',
        'musicGenres',
        'recommendedMood',
      ];

      for (final key in requiredKeys) {
        if (!parsedJson.containsKey(key)) {
          throw Exception('Missing required key in response: $key');
        }
      }

      return parsedJson;
    } catch (e) {
      _logger.error('Error parsing Gemini response: $e');

      // Return a default response
      return {
        'emotionalState': 'Could not analyze emotional state',
        'contentGoal': 'Provide general uplifting content',
        'videoCategories': ['motivational', 'funny', 'relaxing'],
        'musicGenres': ['upbeat', 'relaxing', 'popular'],
        'recommendedMood': 'positive',
      };
    }
  }
}
