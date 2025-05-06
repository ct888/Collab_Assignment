// services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/event.dart';
import '../Model/location.dart';

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
  
  Future<List<Event>> getNearbyEvents(Location location, {int radius = 5000}) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found');
    }
    
    // Create prompt for Gemini
    final prompt = """
    Find nearby events and activities near latitude: ${location.latitude}, longitude: ${location.longitude}.
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
    
    Please find at least 5 diverse events of different types, with accurate event details. Include both free and paid events. Ensure all dates are in the future. For category, ALWAYS provide ONE of these exact values: music, sports, food, art, education, business, technology, health, outdoor. For webUrl, use real-world website domains (like "eventbrite.com/e/example-event", "meetup.com/events/example", etc). Leave imageUrl empty as I'll provide placeholder images.
    """;
    
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
    );
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final text = responseData['candidates'][0]['content']['parts'][0]['text'];
      
      // Extract JSON from response
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']') + 1;
      final jsonStr = text.substring(jsonStart, jsonEnd);
      
      try {
        final List<dynamic> eventsJson = jsonDecode(jsonStr);
        
        // Process each event to add appropriate image URLs based on category
        for (var eventData in eventsJson) {
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
        
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing JSON from Gemini response: $e');
        throw Exception('Failed to parse events from Gemini response');
      }
    } else {
      throw Exception('Failed to get events from Gemini API: ${response.body}');
    }
  }
}