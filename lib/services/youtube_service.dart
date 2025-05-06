import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seek_here/Model/video.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class YouTubeSearchResult {
  final List<VideoItem> videos;
  final String? nextPageToken;

  YouTubeSearchResult({required this.videos, this.nextPageToken});
}

class YouTubeService {
  final http.Client _client;
  final AppLogger _logger = AppLogger();

  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  Future<YouTubeSearchResult> searchVideos(
    List<String> categories, 
    String emotionCategory, 
    {String? pageToken, int maxResults = 20}
  ) async {
    try {
      final List<VideoItem> videos = [];
      String? nextPageToken;
      
      // Instead of querying each category separately, combine categories
      // This reduces API calls significantly
      final queryString = categories.join(' | ');
      
      // final queryParams = {
      //   'part': 'snippet',
      //   'maxResults': maxResults.toString(),
      //   'q': '$queryString short',
      //   'type': 'video',
      //   'videoDuration': 'short',
      //   'key': ApiConstants.youtubeApiKey,
      // };
      final queryParams = {
        'part': 'snippet',
        'maxResults': maxResults.toString(),
        'q': queryString,
        'type': 'video',
        'key': ApiConstants.youtubeApiKey,
      };
      
      // Add page token if present
      if (pageToken != null) {
        queryParams['pageToken'] = pageToken;
      }
      
      final uri = Uri.parse('${ApiConstants.youtubeBaseUrl}${ApiConstants.youtubeSearchEndpoint}')
          .replace(queryParameters: queryParams);
      
      final response = await _client.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Get the next page token if available
        nextPageToken = data['nextPageToken'];
        
        for (var item in data['items']) {
          // Add emotional category to each item
          item['emotionCategory'] = emotionCategory;
          
          final video = VideoItem.fromJson(item);
          videos.add(video);
        }
      } else {
        _logger.error('YouTube API error: ${response.statusCode} - ${response.body}');
        throw Exception('YouTube API returned status code ${response.statusCode}');
      }
      
      return YouTubeSearchResult(videos: videos, nextPageToken: nextPageToken);
    } catch (e) {
      _logger.error('Error searching YouTube videos: $e');
      throw Exception('Failed to search videos: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}