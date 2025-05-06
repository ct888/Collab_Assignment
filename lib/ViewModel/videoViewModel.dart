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

  VideoViewModel({
    YouTubeService? youtubeService,
  }) : _youtubeService = youtubeService ?? YouTubeService();

  List<VideoItem> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get isPaginationLoading => _isPaginationLoading;
  String? get errorMessage => _errorMessage;
  VideoItem? get selectedVideo => _selectedVideo;
  bool get hasMoreVideos => _nextPageToken != null;

  Future<void> fetchRecommendedVideos(List<String> categories, String emotionCategory, {bool refresh = false}) async {
    if (_isLoading) return;
    
    try {
      // If it's a refresh or first load
      if (refresh || _videos.isEmpty) {
        _isLoading = true;
        _errorMessage = null;
        _nextPageToken = null;
        _videos = [];
        _currentCategories = List.from(categories);
        _currentEmotionCategory = emotionCategory;
        notifyListeners();
        
        final result = await _youtubeService.searchVideos(
          categories, 
          emotionCategory, 
          pageToken: null, 
          maxResults: _pageSize
        );
        
        _videos = result.videos;
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
    if (_isPaginationLoading || _nextPageToken == null || _currentCategories == null || _currentEmotionCategory == null) {
      return;
    }

    try {
      _isPaginationLoading = true;
      notifyListeners();

      final result = await _youtubeService.searchVideos(
        _currentCategories!, 
        _currentEmotionCategory!, 
        pageToken: _nextPageToken, 
        maxResults: _pageSize
      );

      _videos.addAll(result.videos);
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