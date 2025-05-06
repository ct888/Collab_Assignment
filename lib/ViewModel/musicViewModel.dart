import 'package:flutter/foundation.dart';
import 'package:seek_here/Model/music.dart';
import 'package:seek_here/services/spotify_service.dart';
import 'package:seek_here/utils/logger.dart';

class MusicViewModel extends ChangeNotifier {
  final SpotifyService _spotifyService;
  final AppLogger _logger = AppLogger();
  
  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  MusicTrack? _selectedTrack;
  bool _isPlaying = false;
  bool _hasMoreTracks = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  List<String> _currentGenres = [];
  String _currentEmotionCategory = '';

  MusicViewModel({
    SpotifyService? spotifyService,
  }) : _spotifyService = spotifyService ?? SpotifyService();

  List<MusicTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  MusicTrack? get selectedTrack => _selectedTrack;
  bool get isPlaying => _isPlaying;
  bool get hasMoreTracks => _hasMoreTracks;

  Future<void> fetchRecommendedTracks(List<String> genres, String emotionCategory, {bool refresh = true}) async {
    try {
      if (refresh) {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
        _hasMoreTracks = true;
        _tracks = [];
        _currentGenres = List.from(genres);
        _currentEmotionCategory = emotionCategory;
        notifyListeners();
      } else {
        // If we're just loading more (not refreshing)
        if (!_hasMoreTracks || _isLoadingMore) {
          return;
        }
        _isLoadingMore = true;
        notifyListeners();
      }

      final newTracks = await _spotifyService.searchTracksWithPagination(
        _currentGenres, 
        _currentEmotionCategory,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // If we received fewer tracks than requested, we've reached the end
      if (newTracks.length < _pageSize) {
        _hasMoreTracks = false;
      }

      if (refresh) {
        _tracks = newTracks;
      } else {
        _tracks.addAll(newTracks);
      }

      _currentPage++;
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Error fetching music tracks: $e');
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = 'Failed to fetch music: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadMoreTracks() async {
    if (!_isLoading && !_isLoadingMore && _hasMoreTracks) {
      await fetchRecommendedTracks(_currentGenres, _currentEmotionCategory, refresh: false);
    }
  }

  Future<void> refreshTracks() async {
    await fetchRecommendedTracks(_currentGenres, _currentEmotionCategory);
  }

  void selectTrack(MusicTrack track) {
    _selectedTrack = track;
    _isPlaying = true;
    notifyListeners();
  }

  void togglePlayback() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void clearSelectedTrack() {
    _selectedTrack = null;
    _isPlaying = false;
    notifyListeners();
  }

  void clearTracks() {
    _tracks = [];
    _currentPage = 0;
    _hasMoreTracks = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _spotifyService.dispose();
    super.dispose();
  }
}