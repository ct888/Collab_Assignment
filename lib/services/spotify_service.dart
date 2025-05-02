import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/music.dart';
import '../utils/logger.dart';

class SpotifyService {
  final http.Client _client;
  final AppLogger _logger = AppLogger();
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  // Cache to store genre results to prevent duplicate API calls
  final Map<String, List<MusicTrack>> _genreCache = {};
  
  SpotifyService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> _getAccessToken() async {
    try {
      // Check if we have a valid token
      if (_accessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        return;
      }

      // Try to get token from local storage
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('spotify_token');
      final expiryString = prefs.getString('spotify_token_expiry');

      if (storedToken != null && expiryString != null) {
        final expiry = DateTime.parse(expiryString);
        if (DateTime.now().isBefore(expiry)) {
          _accessToken = storedToken;
          _tokenExpiry = expiry;
          return;
        }
      }

      // Need to get a new token
      final credentials = base64Encode(
        utf8.encode(
          '${ApiConstants.spotifyClientId}:${ApiConstants.spotifyClientSecret}',
        ),
      );

      final response = await _client.post(
        Uri.parse(ApiConstants.spotifyTokenEndpoint),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        // Calculate expiry (usually 3600 seconds)
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: expiresIn - 300),
        ); // 5 min buffer

        // Store token
        await prefs.setString('spotify_token', _accessToken!);
        await prefs.setString(
          'spotify_token_expiry',
          _tokenExpiry!.toIso8601String(),
        );
      } else {
        throw Exception('Failed to get Spotify token: ${response.body}');
      }
    } catch (e) {
      _logger.error('Error getting Spotify token: $e');
      throw Exception('Failed to authenticate with Spotify: $e');
    }
  }

  // New method with pagination support
  Future<List<MusicTrack>> searchTracksWithPagination(
    List<String> genres,
    String emotionCategory, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      await _getAccessToken();
      
      // If first page, clear cache for these genres to allow refreshing
      if (page == 0) {
        for (final genre in genres) {
          _genreCache.remove('${genre}_$emotionCategory');
        }
      }
      
      final List<MusicTrack> result = [];
      final List<MusicTrack> fallbackTracks = [];
      
      // Calculate distribution of tracks to fetch per genre
      final int tracksPerGenre = (pageSize / genres.length).ceil();
      
      for (final genre in genres) {
        final cacheKey = '${genre}_$emotionCategory';
        List<MusicTrack> genreTracks = _genreCache[cacheKey] ?? [];
        
        // If we don't have enough cached tracks, fetch more
        if (genreTracks.length <= page * tracksPerGenre) {
          // Only make an API call if we need more data
          final fetchedTracks = await _fetchTracksForGenre(
            genre, 
            emotionCategory,
            limit: tracksPerGenre * 2,  // Fetch more than needed to reduce API calls
            offset: genreTracks.length,
          );
          
          // Cache the new tracks
          if (_genreCache.containsKey(cacheKey)) {
            _genreCache[cacheKey]!.addAll(fetchedTracks);
          } else {
            _genreCache[cacheKey] = fetchedTracks;
          }
          
          genreTracks = _genreCache[cacheKey]!;
        }
        
        // Calculate the start and end indices for this page
        final int startIdx = page * tracksPerGenre;
        final int endIdx = (startIdx + tracksPerGenre <= genreTracks.length) 
            ? startIdx + tracksPerGenre 
            : genreTracks.length;
            
        if (startIdx < genreTracks.length) {
          // Add the tracks for this page
          final pageGenreTracks = genreTracks.sublist(startIdx, endIdx);
          
          // Sort tracks with previews first
          for (final track in pageGenreTracks) {
            if (track.hasPreview) {
              result.add(track);
            } else {
              fallbackTracks.add(track);
            }
          }
        }
      }
      
      // Add fallback tracks at the end
      result.addAll(fallbackTracks);
      
      return result;
    } catch (e) {
      _logger.error('Error searching Spotify tracks with pagination: $e');
      throw Exception('Failed to search music: $e');
    }
  }

  // Helper method to fetch tracks for a single genre
  Future<List<MusicTrack>> _fetchTracksForGenre(
    String genre,
    String emotionCategory, {
    int limit = 30,
    int offset = 0,
  }) async {
    final List<MusicTrack> tracks = [];
    
    try {
      final queryParams = {
        'q': 'genre:$genre',
        'type': 'track',
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final uri = Uri.parse(
        '${ApiConstants.spotifyBaseUrl}${ApiConstants.spotifySearchEndpoint}',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        for (var item in data['tracks']['items']) {
          // Add emotional category to each item
          item['emotionCategory'] = emotionCategory;
          tracks.add(MusicTrack.fromJson(item));
        }
      } else {
        _logger.error(
          'Spotify API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _logger.error('Error fetching tracks for genre $genre: $e');
    }
    
    return tracks;
  }

  // Original search method kept for backward compatibility
  Future<List<MusicTrack>> searchTracks(
    List<String> genres,
    String emotionCategory,
  ) async {
    return searchTracksWithPagination(genres, emotionCategory);
  }

  void dispose() {
    _client.close();
    _genreCache.clear();
  }
}