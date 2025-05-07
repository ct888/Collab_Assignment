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
  String? _nextPageToken;
  List<String>? _currentCategories;
  String? _currentEmotionCategory;
  final int _pageSize = 20;

  // Add a set to track video IDs we've already seen to prevent duplicates
  final Set<String> _seenVideoIds = {};

  VideoViewModel({
    YouTubeService? youtubeService,
  }) : _youtubeService = youtubeService ?? YouTubeService();

  List<VideoItem> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get isPaginationLoading => _isPaginationLoading;
  String? get errorMessage => _errorMessage;
  VideoItem? get selectedVideo => _selectedVideo;

  // Explicit getter for hasMoreVideos - will be true when there's a nextPageToken
  bool get hasMoreVideos => _nextPageToken != null && _nextPageToken!.isNotEmpty;

  Future<void> fetchRecommendedVideos(List<String> categories, String emotionCategory, {bool refresh = true}) async {
    if (_isLoading) return;

    try {
      if (refresh) {
        _isLoading = true;
        _errorMessage = null;
        _nextPageToken = null;
        _videos = [];

        // Only clear seen videos if we're doing a full refresh from scratch
        if (_currentCategories == null ||
            _currentEmotionCategory == null ||
            _currentCategories != categories ||
            _currentEmotionCategory != emotionCategory) {
          _seenVideoIds.clear();
        }

        _currentCategories = List.from(categories);
        _currentEmotionCategory = emotionCategory;
        notifyListeners();

        final result = await _youtubeService.searchVideos(
            categories,
            emotionCategory,
            pageToken: null,
            maxResults: _pageSize * 2 // Get extra to filter out duplicates
        );

        // Filter out videos we've already seen
        final newVideos = result.videos.where((video) {
          return !_seenVideoIds.contains(video.videoId);
        }).toList();

        // Add new video IDs to our seen set
        for (var video in newVideos) {
          _seenVideoIds.add(video.videoId);
        }

        // Take only the number we need
        _videos = newVideos.take(_pageSize).toList();

        // Store the nextPageToken - if it's empty or null, we've reached the end
        _nextPageToken = result.nextPageToken;

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

  Future<void> loadMoreVideos() async {
    if (_isPaginationLoading || _nextPageToken == null || _nextPageToken!.isEmpty ||
        _currentCategories == null || _currentEmotionCategory == null) {
      return;
    }

    try {
      _isPaginationLoading = true;
      notifyListeners();

      final result = await _youtubeService.searchVideos(
          _currentCategories!,
          _currentEmotionCategory!,
          pageToken: _nextPageToken,
          maxResults: _pageSize * 2 // Get extra to filter out duplicates
      );

      // Filter out videos we've already seen
      final newVideos = result.videos.where((video) {
        return !_seenVideoIds.contains(video.videoId);
      }).toList();

      // If there are no new videos after filtering, mark as end of list
      if (newVideos.isEmpty) {
        _nextPageToken = null; // Set to null to indicate end of list
        _isPaginationLoading = false;
        notifyListeners();
        return;
      }

      // Add new video IDs to our seen set
      for (var video in newVideos) {
        _seenVideoIds.add(video.videoId);
      }

      _videos.addAll(newVideos.take(_pageSize).toList());

      // Store the nextPageToken - if it's empty or null, we've reached the end
      _nextPageToken = result.nextPageToken;

      _isPaginationLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Error loading more videos: $e');
      _isPaginationLoading = false;
      _errorMessage = 'Failed to load more videos: ${e.toString()}';
      notifyListeners();
    }
  }

  // Add a refreshVideos method similar to MusicViewModel's refreshTracks
  Future<void> refreshVideos() async {
    if (_currentCategories != null && _currentEmotionCategory != null) {
      await fetchRecommendedVideos(_currentCategories!, _currentEmotionCategory!);
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
    _nextPageToken = null;
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