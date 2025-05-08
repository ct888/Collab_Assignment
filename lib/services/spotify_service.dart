import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seek_here/Model/music.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
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

  // Method to fetch tracks for a specific genre
  Future<List<MusicTrack>> searchTracksForGenre(
      String genre,
      String emotionCategory, {
        int page = 0,
        int pageSize = 20,
      }) async {
    try {
      await _getAccessToken();

      final cacheKey = '${genre}_$emotionCategory';
      List<MusicTrack> genreTracks = _genreCache[cacheKey] ?? [];

      // Calculate what we need
      final int startIdx = page * pageSize;
      final int neededCount = startIdx + pageSize;

      // If we don't have enough cached tracks, fetch more
      if (genreTracks.length < neededCount) {
        // Calculate how many more tracks we need
        final limit = (neededCount - genreTracks.length) + 5; // Add some buffer
        final offset = genreTracks.length;

        final fetchedTracks = await _fetchTracksForGenre(
          genre,
          emotionCategory,
          limit: limit,
          offset: offset,
        );

        // If we got no new tracks, we've reached the end
        if (fetchedTracks.isEmpty) {
          return genreTracks.sublist(
              startIdx,
              genreTracks.length > startIdx ? genreTracks.length : startIdx
          );
        }

        // Cache the new tracks
        if (_genreCache.containsKey(cacheKey)) {
          _genreCache[cacheKey]!.addAll(fetchedTracks);
        } else {
          _genreCache[cacheKey] = fetchedTracks;
        }

        genreTracks = _genreCache[cacheKey]!;
      }

      // Return the requested page
      final int endIdx = (startIdx + pageSize <= genreTracks.length)
          ? startIdx + pageSize
          : genreTracks.length;

      if (startIdx < genreTracks.length) {
        return genreTracks.sublist(startIdx, endIdx);
      }

      return [];
    } catch (e) {
      _logger.error('Error searching tracks for genre "$genre": $e');
      // Return empty list rather than throwing to allow other genres to continue
      return [];
    }
  }

  // Improved fetch method with multiple query strategies
  Future<List<MusicTrack>> _fetchTracksForGenre(
      String genre,
      String emotionCategory, {
        int limit = 30,
        int offset = 0,
      }) async {
    final List<MusicTrack> tracks = [];

    try {
      // Try different query strategies for better results
      List<Map<String, String>> queryStrategies = [
        {'q': 'genre:$genre'},  // Standard genre search
        {'q': genre},  // Simple keyword search
        {'q': '$genre music'}, // More general search
      ];

      // Enhanced parameters for better relevance
      final queryParams = {
        'type': 'track',
        'limit': limit.toString(),
        'offset': offset.toString(),
        'market': 'US', // Add a market for more consistent results
      };

      // Try each strategy until we get enough results
      for (var strategy in queryStrategies) {
        if (tracks.length >= limit) break;

        final fullParams = {...queryParams, ...strategy};

        final uri = Uri.parse(
          '${ApiConstants.spotifyBaseUrl}${ApiConstants.spotifySearchEndpoint}',
        ).replace(queryParameters: fullParams);

        final response = await _client.get(
          uri,
          headers: {'Authorization': 'Bearer $_accessToken'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['tracks'] != null && data['tracks']['items'] != null) {
            // Create a set of IDs we already have to avoid duplicates
            final existingIds = tracks.map((t) => t.id).toSet();

            for (var item in data['tracks']['items']) {
              // Skip if we already have this track
              if (existingIds.contains(item['id'])) continue;

              // Add emotional category to each item
              item['emotionCategory'] = emotionCategory;

              final track = MusicTrack.fromJson(item);
              tracks.add(track);
              existingIds.add(track.id);

              // Break out if we've reached our limit
              if (tracks.length >= limit) break;
            }
          }
        } else {
          _logger.error(
            'Spotify API error with strategy ${strategy["q"]}: ${response.statusCode} - ${response.body}',
          );
        }
      }

      // Sort with tracks that have preview URLs first
      tracks.sort((a, b) {
        if (a.hasPreview && !b.hasPreview) return -1;
        if (!a.hasPreview && b.hasPreview) return 1;
        return 0;
      });
    } catch (e) {
      _logger.error('Error fetching tracks for genre $genre: $e');
    }

    return tracks;
  }

  // New method with pagination support for multiple genres
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
        final tracks = await searchTracksForGenre(
          genre,
          emotionCategory,
          page: page,
          pageSize: tracksPerGenre,
        );

        // Sort tracks with previews first
        for (final track in tracks) {
          if (track.hasPreview) {
            result.add(track);
          } else {
            fallbackTracks.add(track);
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

  void dispose() {
    _client.close();
    _genreCache.clear();
  }
}