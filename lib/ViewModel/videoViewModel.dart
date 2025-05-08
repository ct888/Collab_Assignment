import 'package:flutter/foundation.dart';
import 'package:seek_here/Model/video.dart';
import 'package:seek_here/services/youtube_service.dart';
import 'package:seek_here/utils/logger.dart';

class VideoViewModel extends ChangeNotifier {
  final YouTubeService _youtubeService;
  final AppLogger _logger = AppLogger();

  List<VideoItem> _videos = [];
  bool _isLoading = false;
  bool _isPaginationLoading = false;
  String? _errorMessage;
  VideoItem? _selectedVideo;

  // Pagination related properties
  final int _pageSize = 20;

  // Per-category tracking
  final Map<String, String?> _categoryNextPageTokens = {};
  List<String>? _currentCategories;
  String? _currentEmotionCategory;

  // Track seen videos to prevent duplicates
  final Set<String> _seenVideoIds = {};

  // Track retry attempts for failed categories
  final Map<String, int> _categoryRetryAttempts = {};
  final int _maxRetryAttempts = 3;

  // Track category diversity to ensure even representation
  final Map<String, int> _categoryVideoCount = {};

  VideoViewModel({
    YouTubeService? youtubeService,
  }) : _youtubeService = youtubeService ?? YouTubeService();

  List<VideoItem> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get isPaginationLoading => _isPaginationLoading;
  String? get errorMessage => _errorMessage;
  VideoItem? get selectedVideo => _selectedVideo;

  // Check if any category has more videos
  bool get hasMoreVideos {
    if (_currentCategories == null) return false;
    return _currentCategories!.any((category) =>
    _categoryNextPageTokens[category] != null);
  }

  Future<void> fetchRecommendedVideos(List<String> categories, String emotionCategory, {bool refresh = true}) async {
    if (_isLoading) return;

    try {
      if (refresh) {
        _isLoading = true;
        _errorMessage = null;
        _videos = [];
        _categoryNextPageTokens.clear();
        _categoryRetryAttempts.clear();
        _categoryVideoCount.clear();

        // Only clear seen videos if we're doing a full refresh with new categories
        if (_currentCategories == null ||
            _currentEmotionCategory == null ||
            !_areListsEqual(_currentCategories!, categories) ||
            _currentEmotionCategory != emotionCategory) {
          _seenVideoIds.clear();
        }

        _currentCategories = List.from(categories);
        _currentEmotionCategory = emotionCategory;

        // Initialize next page tokens for each category
        for (var category in categories) {
          _categoryNextPageTokens[category] = '';  // Empty string means first page
          _categoryVideoCount[category] = 0;      // Start count at 0
        }

        notifyListeners();

        // Fetch videos from all categories
        await _fetchVideosFromAllCategories();

        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _logger.error('Error fetching videos: $e');
      _isLoading = false;
      _errorMessage = 'Failed to fetch videos: ${e.toString()}';
      notifyListeners();
    }
  }

  // Helper method to compare lists regardless of order
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;

    final set1 = Set<String>.from(list1);
    final set2 = Set<String>.from(list2);

    return set1.difference(set2).isEmpty;
  }

  // Helper method to fetch videos from all categories with balancing
  Future<void> _fetchVideosFromAllCategories() async {
    if (_currentCategories == null || _currentEmotionCategory == null) return;

    final List<VideoItem> allVideos = [];

    // Calculate videos per category, but adjust for categories that need more attention
    final categoriesWithVideos = _currentCategories!.where((category) =>
    _categoryNextPageTokens[category] != null).toList();

    if (categoriesWithVideos.isEmpty) return;

    // Calculate base allocation per category
    int videosPerCategory = (_pageSize / categoriesWithVideos.length).ceil();

    // Sort categories to prioritize those with fewer videos
    categoriesWithVideos.sort((a, b) =>
        (_categoryVideoCount[a] ?? 0).compareTo(_categoryVideoCount[b] ?? 0));

    // Allocate more videos to categories with fewer results
    Map<String, int> requestAllocation = {};
    for (var category in categoriesWithVideos) {
      // Categories with fewer videos get higher allocation
      final currentCount = _categoryVideoCount[category] ?? 0;
      final double balanceFactor = currentCount == 0 ? 2.0 :
      currentCount < 5 ? 1.5 : 1.0;

      requestAllocation[category] = (videosPerCategory * balanceFactor).ceil();
    }

    // Fetch videos for each category in parallel with dynamic allocation
    final futures = categoriesWithVideos.map((category) async {
      // Skip categories that have been marked as exhausted
      if (_categoryNextPageTokens[category] == null) return <VideoItem>[];

      try {
        final result = await _youtubeService.searchVideosForCategory(
          category,
          _currentEmotionCategory!,
          pageToken: _categoryNextPageTokens[category]!.isEmpty ? null : _categoryNextPageTokens[category],
          maxResults: requestAllocation[category]! * 2, // Get extra to filter duplicates
        );

        // Reset retry count on successful fetch
        _categoryRetryAttempts[category] = 0;

        // Filter out videos we've already seen
        final newVideos = result.videos.where((video) {
          return !_seenVideoIds.contains(video.videoId);
        }).toList();

        // Add new video IDs to seen set
        for (var video in newVideos) {
          _seenVideoIds.add(video.videoId);
        }

        // Update next page token for this category
        _categoryNextPageTokens[category] = result.nextPageToken;

        // If no next page token or no new videos, mark this category as completed
        if (result.nextPageToken == null || result.nextPageToken!.isEmpty || newVideos.isEmpty) {
          _categoryNextPageTokens[category] = null;
        }

        // Update the count of videos for this category
        _categoryVideoCount[category] = (_categoryVideoCount[category] ?? 0) + newVideos.length;

        return newVideos.take(requestAllocation[category]!).toList();
      } catch (e) {
        _logger.error('Error fetching videos for category "$category": $e');

        // Implement retry logic
        final retryCount = (_categoryRetryAttempts[category] ?? 0) + 1;
        _categoryRetryAttempts[category] = retryCount;

        if (retryCount >= _maxRetryAttempts) {
          // If we've tried too many times, mark this category as completed
          _categoryNextPageTokens[category] = null;
          _logger.info('Giving up on category "$category" after $retryCount attempts');
        }

        return <VideoItem>[];
      }
    }).toList();

    // Wait for all fetches to complete
    final results = await Future.wait(futures);

    // Combine and intersperse results for better diversity
    if (results.isNotEmpty) {
      // Create a list of lists for interspersing
      List<List<VideoItem>> categoryResults = [];
      for (var categoryVideos in results) {
        if (categoryVideos.isNotEmpty) {
          categoryResults.add(categoryVideos);
        }
      }

      // Intersperse videos for better diversity
      if (categoryResults.isNotEmpty) {
        allVideos.addAll(_interleaveResults(categoryResults));
      }
    }

    // Add to our collection and notify
    _videos.addAll(allVideos);
  }

  // Helper to intersperse videos from different categories
  List<VideoItem> _interleaveResults(List<List<VideoItem>> categoryResults) {
    List<VideoItem> interleaved = [];
    int maxLength = categoryResults.fold(0, (max, list) =>
    list.length > max ? list.length : max);

    for (int i = 0; i < maxLength; i++) {
      for (var videoList in categoryResults) {
        if (i < videoList.length) {
          interleaved.add(videoList[i]);
        }
      }
    }

    return interleaved;
  }

  Future<void> loadMoreVideos() async {
    if (_isPaginationLoading || !hasMoreVideos ||
        _currentCategories == null || _currentEmotionCategory == null) {
      return;
    }

    try {
      _isPaginationLoading = true;
      notifyListeners();

      await _fetchVideosFromAllCategories();

      _isPaginationLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Error loading more videos: $e');
      _isPaginationLoading = false;
      _errorMessage = 'Failed to load more videos: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> refreshVideos() async {
    if (_currentCategories != null && _currentEmotionCategory != null) {
      await fetchRecommendedVideos(_currentCategories!, _currentEmotionCategory!);
    }
  }

  Future<void> fetchVideosForCategory(String category, String emotionCategory, {bool append = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;

      if (!append) {
        // If not appending, start fresh for this category
        _categoryNextPageTokens[category] = '';
        _categoryVideoCount[category] = 0;

        // If replacing all videos, clear current list
        _videos = [];
      }

      notifyListeners();

      final result = await _youtubeService.searchVideosForCategory(
        category,
        emotionCategory,
        pageToken: _categoryNextPageTokens[category]!.isEmpty ? null : _categoryNextPageTokens[category],
        maxResults: _pageSize * 2,
      );

      // Filter out videos we've already seen
      final newVideos = result.videos.where((video) {
        return !_seenVideoIds.contains(video.videoId);
      }).toList();

      // Add new video IDs to seen set
      for (var video in newVideos) {
        _seenVideoIds.add(video.videoId);
      }

      // Update next page token for this category
      _categoryNextPageTokens[category] = result.nextPageToken;

      // Update count
      _categoryVideoCount[category] = (_categoryVideoCount[category] ?? 0) + newVideos.length;

      if (append) {
        _videos.addAll(newVideos);
      } else {
        _videos = newVideos;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Error fetching videos for category "$category": $e');
      _isLoading = false;
      _errorMessage = 'Failed to fetch videos: ${e.toString()}';
      notifyListeners();
    }
  }

  void selectVideo(VideoItem video) {
    _selectedVideo = video;
    notifyListeners();
  }

  void clearSelectedVideo() {
    _selectedVideo = null;
    notifyListeners();
  }

  void clearVideos() {
    _videos = [];
    _categoryNextPageTokens.clear();
    _categoryRetryAttempts.clear();
    _categoryVideoCount.clear();
    _currentCategories = null;
    _currentEmotionCategory = null;
    _seenVideoIds.clear(); // Also clear seen video IDs
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}