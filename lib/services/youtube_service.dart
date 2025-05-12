import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seek_here/Model/video.dart';
import '../Model/constants/api_constants.dart';
import '../utils/logger.dart';
import 'dart:async';

class YouTubeSearchResult {
  final List<VideoItem> videos;
  final String? nextPageToken;

  YouTubeSearchResult({required this.videos, this.nextPageToken});
}

class YouTubeService {
  final http.Client _client;
  final AppLogger _logger = AppLogger();

  // Enhanced cache to store category results with expiration
  final Map<String, Map<String, dynamic>> _categoryCache = {};
  final Map<String, DateTime> _cacheTimes = {};
  final Duration _cacheDuration = Duration(hours: 12);

  // Rate limiting tracker
  final int _maxRequestsPerMinute = 5;
  final List<DateTime> _requestTimestamps = [];

  // Video quota tracker - YouTube API has a quota limit (usually 10,000 units per day)
  // Search requests cost 100 units per call
  int _dailyQuotaUsed = 0;
  final int _maxDailyQuota = 10000;
  DateTime _quotaResetDate = DateTime.now();

  // Batch processing variables
  final Map<String, List<VideoItem>> _batchVideoBuffer = {};
  final Map<String, Completer<YouTubeSearchResult>> _pendingRequests = {};
  Timer? _batchTimer;
  final Duration _batchDelay = Duration(milliseconds: 300);

  YouTubeService({http.Client? client}) : _client = client ?? http.Client() {
    // Reset quota counter at midnight
    _scheduleQuotaReset();
  }

  void _scheduleQuotaReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final millisUntilMidnight = tomorrow.difference(now).inMilliseconds;

    Timer(Duration(milliseconds: millisUntilMidnight), () {
      _dailyQuotaUsed = 0;
      _quotaResetDate = tomorrow;
      _scheduleQuotaReset(); // Schedule the next reset
    });
  }

  /// Batch multiple requests for the same category
  Future<YouTubeSearchResult> searchVideos(
      List<String> categories,
      String emotionCategory,
      {String? pageToken, int maxResults = 20}
      ) async {
    try {
      // Calculate videos per category with a minimum to ensure diversity
      final int videosPerCategory = (maxResults / categories.length).ceil();
      final int minVideosPerCategory = 2; // Ensure at least 2 videos per category

      final List<VideoItem> allVideos = [];
      String? globalNextPageToken;

      // Prioritize categories by implementing a scoring system
      // This allows us to fetch more from high-priority categories
      List<Map<String, dynamic>> prioritizedCategories = categories.map((category) {
        // Check if we have this category cached already
        bool isCached = _isCategoryInCache(category);

        // Priority score: uncached categories get higher priority
        int priorityScore = isCached ? 1 : 2;

        return {
          'category': category,
          'priority': priorityScore,
          'videosToFetch': videosPerCategory
        };
      }).toList();

      // Sort by priority (higher priority first)
      prioritizedCategories.sort((a, b) => b['priority'] - a['priority']);

      // Process categories in priority order
      for (final categoryData in prioritizedCategories) {
        final category = categoryData['category'];
        final videosToFetch = categoryData['videosToFetch'];

        // If we've already hit our quota limit, use cached data only
        if (_willExceedQuota(1)) {
          final cachedResult = _getFromCache(category);
          if (cachedResult != null) {
            final cachedVideos = cachedResult['items'].map<VideoItem>((item) {
              // Add emotional category to each item
              item['emotionCategory'] = emotionCategory;
              return VideoItem.fromJson(item);
            }).toList().cast<VideoItem>();

            allVideos.addAll(cachedVideos.take(videosToFetch));
            continue;
          } else {
            // Skip this category if no cached data
            _logger.info('Skipping search for "$category" - API quota limit reached');
            continue;
          }
        }

        // Check if we need to wait due to rate limiting
        await _enforceRateLimit();

        try {
          final result = await _searchSingleCategory(
            category,
            emotionCategory,
            pageToken: pageToken,
            maxResults: videosToFetch,
          );

          allVideos.addAll(result.videos);

          // Keep track of the last page token for continuation
          if (result.nextPageToken != null) {
            globalNextPageToken = result.nextPageToken;
          }

          // Track this request for rate limiting
          _requestTimestamps.add(DateTime.now());
          _dailyQuotaUsed += 100; // Each search request costs 100 units

        } catch (e) {
          _logger.error('Error fetching videos for category "$category": $e');
          // Continue with other categories if one fails
        }
      }

      // If we didn't get enough videos in total, try to fetch more from cached categories
      final int minTotalVideos = categories.length * minVideosPerCategory;
      if (allVideos.length < minTotalVideos) {
        // Get more videos from cached categories
        for (final category in categories) {
          if (allVideos.length >= maxResults) break;

          final cachedResult = _getFromCache(category);
          if (cachedResult != null) {
            final cachedVideos = cachedResult['items'].map<VideoItem>((item) {
              // Add emotional category to each item
              item['emotionCategory'] = emotionCategory;
              return VideoItem.fromJson(item);
            }).toList().cast<VideoItem>();

            // Add videos that aren't already in our result
            final existingIds = allVideos.map((v) => v.videoId).toSet();
            final newVideos = cachedVideos.where((v) => !existingIds.contains(v.videoId)).toList();

            allVideos.addAll(newVideos.take(maxResults - allVideos.length));
          }
        }
      }

      // Shuffle videos slightly to mix categories while maintaining some order
      _shuffleWithBias(allVideos);

      return YouTubeSearchResult(videos: allVideos, nextPageToken: globalNextPageToken);
    } catch (e) {
      _logger.error('Error searching YouTube videos: $e');
      throw Exception('Failed to search videos: $e');
    }
  }

  // Helper method to shuffle list while maintaining some ordering bias
  void _shuffleWithBias(List items) {
    if (items.length <= 1) return;

    for (int i = 0; i < items.length - 1; i++) {
      // 30% chance of swapping with a nearby item
      if (i % 3 == 0) {
        int j = i + 1;
        final temp = items[i];
        items[i] = items[j];
        items[j] = temp;
      }
    }
  }

  // Batch multiple API requests for the same category
  Future<YouTubeSearchResult> _searchSingleCategory(
      String category,
      String emotionCategory,
      {String? pageToken, int maxResults = 10}
      ) async {
    // Create a unique key for this request
    final requestKey = '${category}_${pageToken ?? "initial"}_$maxResults';

    // Check if there's already a pending request for this key
    if (_pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey]!.future;
    }

    // Create a new completer for this request
    final completer = Completer<YouTubeSearchResult>();
    _pendingRequests[requestKey] = completer;

    // Check cache first if we're not using a page token
    if (pageToken == null) {
      final cacheResult = _getFromCacheWithEmotionCategory(category, emotionCategory, maxResults);
      if (cacheResult != null) {
        _pendingRequests.remove(requestKey);
        return cacheResult;
      }
    }

    // If we have a batch timer active, add this request to the batch
    if (_batchTimer != null) {
      _scheduleBatchRequest(category, emotionCategory, pageToken, maxResults, requestKey);
      return completer.future;
    }

    // Start a new batch
    _batchTimer = Timer(_batchDelay, () {
      _processBatchRequests();
    });

    _scheduleBatchRequest(category, emotionCategory, pageToken, maxResults, requestKey);
    return completer.future;
  }

  void _scheduleBatchRequest(String category, String emotionCategory, String? pageToken, int maxResults, String requestKey) {
    _batchVideoBuffer[requestKey] = [];

    // Schedule the API request
    Future.delayed(_batchDelay, () async {
      try {
        final result = await _executeApiRequest(category, emotionCategory, pageToken, maxResults);

        // Complete the pending request if it still exists
        if (_pendingRequests.containsKey(requestKey)) {
          _pendingRequests[requestKey]!.complete(result);
          _pendingRequests.remove(requestKey);
        }
      } catch (e) {
        // Complete with error
        if (_pendingRequests.containsKey(requestKey)) {
          _pendingRequests[requestKey]!.completeError(e);
          _pendingRequests.remove(requestKey);
        }
      }
    });
  }

  void _processBatchRequests() {
    _batchTimer = null;
    // All requests are scheduled individually with their own delays
  }

  Future<YouTubeSearchResult> _executeApiRequest(
      String category,
      String emotionCategory,
      String? pageToken,
      int maxResults
      ) async {
    try {
      final List<VideoItem> videos = [];
      String? nextPageToken;

      // Check if we have a recent enough cache
      final cacheKey = category.toLowerCase();
      if (pageToken == null && _isCategoryInCache(cacheKey)) {
        final cachedData = _getFromCache(cacheKey)!;

        // Convert cached JSON data back to VideoItems
        for (var item in cachedData['items']) {
          // Add emotional category to each item
          item['emotionCategory'] = emotionCategory;
          final video = VideoItem.fromJson(item);
          videos.add(video);
        }

        nextPageToken = cachedData['nextPageToken'];

        // If we have enough cached videos, return them
        if (videos.length >= maxResults) {
          return YouTubeSearchResult(
              videos: videos.take(maxResults).toList(),
              nextPageToken: nextPageToken
          );
        }
      }

      // If not enough in cache or using page token, make API call
      // Try different query strategies for better results
      List<Map<String, String>> queryStrategies = [];

      // Determine the most effective strategies based on category
      if (category.toLowerCase().contains('music') ||
          category.toLowerCase().contains('song') ||
          category.toLowerCase().contains('audio')) {
        queryStrategies = [
          {'q': '$category short music'},
          {'q': '$category song'},
          {'q': category},
        ];
      } else if (category.toLowerCase().contains('comedy') ||
          category.toLowerCase().contains('funny')) {
        queryStrategies = [
          {'q': '$category short funny'},
          {'q': '$category clip'},
          {'q': category},
        ];
      } else {
        queryStrategies = [
          {'q': '$category short'},
          {'q': category},
          {'q': '$category trending'},
        ];
      }

      bool foundResults = false;

      for (var strategy in queryStrategies) {
        if (videos.length >= maxResults) break;
        if (foundResults) break; // Stop after first successful strategy

        final queryParams = {
          'part': 'snippet',
          'maxResults': maxResults.toString(),
          'type': 'video',
          'videoDuration': 'short', // Prefer short videos
          'key': ApiConstants.youtubeApiKey,
          ...strategy,
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
          foundResults = true;

          // Update our cache if this is a fresh search
          if (pageToken == null) {
            _updateCache(cacheKey, data);
          }

          // Get the next page token if available
          nextPageToken = data['nextPageToken'];

          // Create a set of existing IDs to prevent duplicates
          final existingIds = videos.map((v) => v.videoId).toSet();

          for (var item in data['items']) {
            // Skip if we already have this video
            if (existingIds.contains(item['id']['videoId'])) continue;

            // Add emotional category to each item
            item['emotionCategory'] = emotionCategory;

            final video = VideoItem.fromJson(item);
            videos.add(video);
            existingIds.add(video.videoId);

            // Break if we have enough videos
            if (videos.length >= maxResults) break;
          }
        } else {
          _logger.error('YouTube API error with strategy ${strategy["q"]}: ${response.statusCode} - ${response.body}');

          // Check for quota exceeded error
          if (response.statusCode == 403 && response.body.contains('quotaExceeded')) {
            _dailyQuotaUsed = _maxDailyQuota; // Mark quota as exceeded
            throw Exception('YouTube API quota exceeded. Try again tomorrow.');
          }
        }
      }

      return YouTubeSearchResult(videos: videos, nextPageToken: nextPageToken);
    } catch (e) {
      _logger.error('Error searching for category "$category": $e');
      // Return empty result rather than throwing to allow other categories to continue
      return YouTubeSearchResult(videos: []);
    }
  }

  // Check if we have this category in cache and it's still valid
  bool _isCategoryInCache(String category) {
    final cacheKey = category.toLowerCase();
    if (!_categoryCache.containsKey(cacheKey)) return false;
    if (!_cacheTimes.containsKey(cacheKey)) return false;

    final cacheTime = _cacheTimes[cacheKey]!;
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheDuration;
  }

  // Get data from cache
  Map<String, dynamic>? _getFromCache(String category) {
    final cacheKey = category.toLowerCase();
    if (!_isCategoryInCache(cacheKey)) return null;
    return _categoryCache[cacheKey];
  }

  // Update cache with new data
  void _updateCache(String category, Map<String, dynamic> data) {
    final cacheKey = category.toLowerCase();
    _categoryCache[cacheKey] = data;
    _cacheTimes[cacheKey] = DateTime.now();

    // Clean up old cache entries
    _cleanupCache();
  }

  // Clean up old cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _cacheTimes.forEach((key, time) {
      if (now.difference(time) > _cacheDuration) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _categoryCache.remove(key);
      _cacheTimes.remove(key);
    }
  }

  // Get videos from cache with emotion category added
  YouTubeSearchResult? _getFromCacheWithEmotionCategory(
      String category,
      String emotionCategory,
      int maxResults
      ) {
    final cacheKey = category.toLowerCase();
    if (!_isCategoryInCache(cacheKey)) return null;

    final cachedData = _categoryCache[cacheKey]!;
    final videos = <VideoItem>[];

    for (var item in cachedData['items']) {
      // Add emotional category to each item
      item['emotionCategory'] = emotionCategory;
      final video = VideoItem.fromJson(item);
      videos.add(video);

      if (videos.length >= maxResults) break;
    }

    return YouTubeSearchResult(
        videos: videos,
        nextPageToken: cachedData['nextPageToken']
    );
  }

  // Enforce rate limiting
  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();

    // Remove timestamps older than 1 minute
    _requestTimestamps.removeWhere(
            (timestamp) => now.difference(timestamp).inMinutes >= 1
    );

    // If we've made too many requests in the past minute, wait
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldestTimestamp = _requestTimestamps.first;
      final timeToWait = Duration(minutes: 1) - now.difference(oldestTimestamp);

      if (timeToWait.isNegative) {
        return; // No need to wait
      }

      _logger.info('Rate limit reached. Waiting for ${timeToWait.inMilliseconds}ms');
      await Future.delayed(timeToWait);
    }
  }

  // Check if making a request would exceed quota
  bool _willExceedQuota(int requestCount) {
    // Each search request costs 100 units
    final quotaCost = requestCount * 100;
    return _dailyQuotaUsed + quotaCost > _maxDailyQuota;
  }

  // Method to fetch videos for a single category with pagination
  Future<YouTubeSearchResult> searchVideosForCategory(
      String category,
      String emotionCategory,
      {String? pageToken, int maxResults = 20}
      ) async {
    return _searchSingleCategory(
        category,
        emotionCategory,
        pageToken: pageToken,
        maxResults: maxResults
    );
  }

  void dispose() {
    _batchTimer?.cancel();
    _client.close();
  }
}