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

  // Pagination and tracking
  bool _hasMoreTracks = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  List<String> _currentGenres = [];
  String _currentEmotionCategory = '';

  // Track seen music to avoid duplicates
  final Set<String> _seenTrackIds = {};

  // Keep track of per-genre pagination
  final Map<String, int> _genreCurrentPages = {};
  final Map<String, bool> _genreHasMoreTracks = {};

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

        // Reset per-genre pagination tracking
        _genreCurrentPages.clear();
        _genreHasMoreTracks.clear();
        _seenTrackIds.clear();

        // Initialize pagination tracking for each genre
        for (var genre in genres) {
          _genreCurrentPages[genre] = 0;
          _genreHasMoreTracks[genre] = true;
        }

        notifyListeners();
      } else {
        // If we're just loading more (not refreshing)
        if (!_hasMoreTracks || _isLoadingMore) {
          return;
        }
        _isLoadingMore = true;
        notifyListeners();
      }

      final List<MusicTrack> newTracks = [];
      bool anyGenreHasMoreTracks = false;

      // Calculate how many tracks to fetch per genre
      final int tracksPerGenre = (_pageSize / genres.length).ceil();

      // Fetch tracks from each genre that still has more content
      for (var genre in genres) {
        if (_genreHasMoreTracks[genre] == true) {
          final genreTracks = await _spotifyService.searchTracksForGenre(
            genre,
            _currentEmotionCategory,
            page: _genreCurrentPages[genre]!,
            pageSize: tracksPerGenre,
          );

          // Filter out tracks we've already seen
          final uniqueTracks = genreTracks.where((track) {
            return !_seenTrackIds.contains(track.id);
          }).toList();

          // Add new track IDs to our seen set
          for (var track in uniqueTracks) {
            _seenTrackIds.add(track.id);
          }

          // Add the unique tracks to our results
          newTracks.addAll(uniqueTracks);

          // Update the pagination for this genre
          _genreCurrentPages[genre] = _genreCurrentPages[genre]! + 1;

          // Check if we've reached the end for this genre
          if (genreTracks.length < tracksPerGenre) {
            _genreHasMoreTracks[genre] = false;
          } else {
            anyGenreHasMoreTracks = true;
          }
        }
      }

      // Prioritize tracks with previews
      newTracks.sort((a, b) {
        if (a.hasPreview && !b.hasPreview) return -1;
        if (!a.hasPreview && b.hasPreview) return 1;
        return 0;
      });

      if (refresh) {
        _tracks = newTracks;
      } else {
        _tracks.addAll(newTracks);
      }

      _currentPage++;
      _hasMoreTracks = anyGenreHasMoreTracks;
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
    _genreCurrentPages.clear();
    _genreHasMoreTracks.clear();
    _seenTrackIds.clear();
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