import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Model/event.dart';
import '../Model/location.dart';
import '../Model/mood.dart';
import '../Model/diary_entry.dart';

class GeminiService {
  final String apiKey = 'AIzaSyB9fu7WWZ3zyrkIFzIfkzTXNhnuKeERJ-8';
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // List of fallback event images for different categories
  final Map<String, String> _categoryImageUrls = {
    'music': 'https://images.unsplash.com/photo-1501612780327-45045538702b?q=80&w=1000',
    'sports': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1000',
    'food': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000',
    'art': 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?q=80&w=1000',
    'education': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?q=80&w=1000',
    'business': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=1000',
    'technology': 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=1000',
    'health': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=1000',
    'outdoor': 'https://images.unsplash.com/photo-1445307806294-bff7f67ff225?q=80&w=1000',
    'default': 'https://images.unsplash.com/photo-1472653431158-6364773b2a56?q=80&w=1000',
  };
  
  // New method for personalized event recommendations with improved error handling
  Future<List<Event>> getPersonalizedEvents(
    Location location, 
    UserMood? mood, 
    DiaryEntry? diaryEntry,
    {int radius = 5000}
  ) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found');
    }
    
    // Create a more personalized prompt based on user's mood and diary content
    String moodContext = '';
    String diaryContext = '';
    
    // Add mood context if available and valid
    if (mood != null && mood.moodType.isNotEmpty) {
      moodContext = """
      The user is currently feeling ${mood.moodType}. 
      Associated notes with this mood: ${mood.notes.join(', ')}.
      Based on this mood, prioritize events that would be appropriate and beneficial.
      """;
      
      // Add specific recommendations based on mood type
      switch (mood.moodType.toLowerCase()) {
        case 'happy':
        case 'excited':
        case 'energetic':
          moodContext += " Since the user is feeling positive and energetic, include active and social events.";
          break;
        case 'sad':
        case 'depressed':
        case 'low':
          moodContext += " Since the user is feeling down, include uplifting, calming, or supportive events.";
          break;
        case 'anxious':
        case 'stressed':
          moodContext += " Since the user is feeling stressed, include relaxing, mindful, or low-pressure events.";
          break;
        case 'tired':
        case 'exhausted':
          moodContext += " Since the user is feeling tired, include more relaxed and less physically demanding events.";
          break;
      }
    } else {
      moodContext += " Since the user does not record any mood, include regular event nearby the address.";
      debugPrint('No valid mood data available for personalization');
    }
    
    // Add diary context if available and valid
    if (diaryEntry != null && diaryEntry.content.isNotEmpty) {
      diaryContext = """
      From the user's recent diary entry, here are some insights:
      "${diaryEntry.content}"
      Please analyze the content for interests, hobbies, or concerns and tailor event recommendations accordingly.
      """;
    } else {
      debugPrint('No valid diary data available for personalization');
      diaryContext = "";
    }
    
    // Create prompt for Gemini with personalization
    final prompt = """
    Find nearby events and activities around latitude: ${location.latitude}, longitude: ${location.longitude} that would be personally relevant to a user.

    $moodContext
    $diaryContext

    Please provide the following details for each event:
    1. Event title
    2. Organizer
    3. Description
    4. Location address
    5. Date and time (in YYYY-MM-DD HH:MM format)
    6. Entry fee or cost per person (in Ringgit,RM)
    7. Category (music, sports, food, art, education, business, technology, health, or outdoor)
    8. Website link or more information source
    9. Requirement for joining or participate the events

    Please find at least 6-8 diverse events of different types, with accurate event details occurs between 5 June 2025 until 5 August 2025.
    Include both free and paid events. Ensure all events must be organise or conduct in the future(compare to today date).  
    For category, ALWAYS provide ONE of these exact values: music, sports, food, art, education, business, technology, health, outdoor. 
    For webUrl, use real-world website domains (like "eventbrite.com/e/example-event", "meetup.com/events/example", etc).
    Please ensure the webUrl are valid and related to the event or activities
    Leave imageUrl empty as I'll provide placeholder images.

    For each event, briefly explain why it might be relevant based on the user's current mood and/or diary content.

    Please return the information in the following JSON format:
    [
      {
        "id": "unique_id",
        "title": "Event Title",
        "organizer": "Event Organizer",
        "location": {
          "latitude": 0.0,
          "longitude": 0.0,
          "address": "Full address"
        },
        "startDate": "2025-05-02T18:00:00Z",
        "endDate": "2025-05-02T21:00:00Z",
        "fee": 0.0,
        "description": "Detailed description of the event",
        "category": "music, sports, food, art, education, business, technology, health, or outdoor",
        "imageUrl": "",
        "webUrl": "website_url",
        "requirements": ["requirement1", "requirement2"]
      }
    ]
    """;

    debugPrint('Sending personalized prompt to Gemini API');
    debugPrint('Prompt : ${prompt}');
    
    try {
      return await _fetchEventsFromGemini(prompt);
    } catch (e) {
      debugPrint('Error in getPersonalizedEvents: $e');
      // If personalized events fail, try falling back to regular events
      debugPrint('Falling back to regular events after personalization failure');
      return await getNearbyEvents(location);
    }
  }

  Future<List<Event>> getNearbyEvents(Location location, {int radius = 5000}) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found');
    }
    
    // Create prompt for Gemini
    final prompt = """
    Find nearby events and activities around latitude: ${location.latitude}, longitude: ${location.longitude}.

      Please provide the following details for each event:
      1. Event title
      2. Organizer
      3. Description
      4. Location address
      5. Date and time (in YYYY-MM-DD HH:MM format)
      6. Entry fee or cost per person (in Ringgit,RM)
      7. Category (music, sports, food, art, education, business, technology, health, or outdoor)
      8. Website link or more information source
      9. Requirement for joining or participate the events

    Please find at least 6-8 diverse events of different types, with accurate event details occurs between 5 June 2025 until 5 August 2025.
    Include both free and paid events. Ensure all events must be organise or conduct in the future(compare to today date).  
    For category, ALWAYS provide ONE of these exact values: music, sports, food, art, education, business, technology, health, outdoor. 
    For webUrl, use real-world website domains (like "eventbrite.com/e/example-event", "meetup.com/events/example", etc).
    Please ensure the webUrl are valid and related to the event or activities
    Leave imageUrl empty as I'll provide placeholder images.

    Please return the information in the following JSON format:
    [
      {
        "id": "unique_id",
        "title": "Event Title",
        "organizer": "Event Organizer",
        "location": {
          "latitude": 0.0,
          "longitude": 0.0,
          "address": "Full address"
        },
        "startDate": "2025-05-02T18:00:00Z",
        "endDate": "2025-05-02T21:00:00Z",
        "fee": 0.0,
        "description": "Detailed description of the event",
        "category": "music, sports, food, art, education, business, technology, health, or outdoor",
        "imageUrl": "",
        "webUrl": "website_url",
        "requirements": ["requirement1", "requirement2"]
      }
    ]
    """;
    
    debugPrint('Sending regular prompt to Gemini API');
    debugPrint('Prompt : ${prompt}');
    
    try {
      return await _fetchEventsFromGemini(prompt);
    } catch (e) {
      debugPrint('Error in getNearbyEvents: $e');
      rethrow;
    }
  }

  // Extracted common event fetching logic to reduce code duplication
  Future<List<Event>> _fetchEventsFromGemini(String prompt) async {
    try {
      // Prepare request to Gemini API
      final url = '$baseUrl?key=$apiKey';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30), // Increased timeout for complex processing
        onTimeout: () {
          throw Exception('Request to Gemini API timed out');
        },
      );

      debugPrint('🔍 Gemini Service Response Status: ${response.statusCode}');
      debugPrint('🔍 Gemini Service Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if we have valid candidates array
        if (responseData['candidates'] == null || 
            responseData['candidates'].isEmpty || 
            responseData['candidates'][0]['content'] == null ||
            responseData['candidates'][0]['content']['parts'] == null ||
            responseData['candidates'][0]['content']['parts'].isEmpty) {
          throw Exception('Invalid response structure from Gemini API');
        }
        
        final text = responseData['candidates'][0]['content']['parts'][0]['text'];
        
        // Check if text is empty or null
        if (text == null || text.isEmpty) {
          throw Exception('Empty response from Gemini API');
        }
        
        // Extract JSON from response with better error handling
        int? jsonStart = text.indexOf('[');
        int? jsonEnd = text.lastIndexOf(']') + 1;
        
        if (jsonStart! < 0 || jsonEnd! <= 0 || jsonStart >= jsonEnd) {
          throw Exception('Could not find valid JSON array in Gemini response');
        }
        
        final jsonStr = text.substring(jsonStart, jsonEnd);
        
        try {
          final List<dynamic> eventsJson = jsonDecode(jsonStr);
          
          // Validate events - make sure we have at least one valid event
          if (eventsJson.isEmpty) {
            throw Exception('No events found in the response');
          }
          
          // Process each event to add appropriate image URLs based on category
          for (var eventData in eventsJson) {
            // Add checks for required fields
            if (eventData['title'] == null || eventData['organizer'] == null) {
              debugPrint('Warning: Event missing required fields: $eventData');
              continue; // Skip invalid events
            }
            
            if (eventData['imageUrl'] == null || eventData['imageUrl'].isEmpty) {
              // Get the event category or default to 'default'
              final category = (eventData['category'] as String?)?.toLowerCase() ?? 'default';
              
              // Find appropriate image URL based on category
              String imageUrl = _categoryImageUrls['default']!;
              for (final key in _categoryImageUrls.keys) {
                if (category.contains(key)) {
                  imageUrl = _categoryImageUrls[key]!;
                  break;
                }
              }
              
              // Set the image URL
              eventData['imageUrl'] = imageUrl;
            }
            
            // Ensure webUrl is properly formatted
            if (eventData['webUrl'] != null && !eventData['webUrl'].toString().startsWith('http')) {
              eventData['webUrl'] = 'https://' + eventData['webUrl'];
            }
          }
          
          // Convert to Event objects with error handling for individual events
          List<Event> events = [];
          for (var json in eventsJson) {
            try {
              events.add(Event.fromJson(json));
            } catch (e) {
              debugPrint('Error creating Event from JSON: $e for data: $json');
              // Continue with other events
            }
          }
          
          if (events.isEmpty) {
            throw Exception('Could not create any valid events from the response');
          }
          
          debugPrint('✅ Successfully retrieved ${events.length} events');
          return events;
        } catch (e) {
          debugPrint('Error parsing JSON from Gemini response: $e');
          debugPrint('Raw JSON string: $jsonStr');
          throw Exception('Failed to parse events from Gemini response: $e');
        }
      } else {
        debugPrint('Gemini API error response: ${response.body}');
        throw Exception('Failed to get events from Gemini API: ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw with more context if needed
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error in _fetchEventsFromGemini: $e');
    }
  }
}