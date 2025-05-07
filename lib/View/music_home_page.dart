import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/View/mood_selection_page.dart';
import 'package:seek_here/ViewModel/moodViewModel.dart';
import 'package:seek_here/ViewModel/musicViewModel.dart';
import 'package:seek_here/widgets/music_player_widget.dart';
import 'package:seek_here/widgets/recommendation_list.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({Key? key}) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  bool showAnalysis = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Initial load of tracks
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      setState(() {
        _isInitialLoading = false;
      });
    });
  }

  // Improved method to load data that can be called whenever needed
  Future<void> _loadData() async {
    final musicViewModel = Provider.of<MusicViewModel>(context, listen: false);
    final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);

    // First, fetch the mood from Firebase
    await moodViewModel.fetchLatestData();

    // Only proceed if we have a mood (regardless of when it was recorded)
    if (moodViewModel.currentMood != null) {
      // Analyze emotion based on the current mood
      await moodViewModel.analyzeEmotion();

      // Then fetch music recommendations based on analysis
      await musicViewModel.fetchRecommendedTracks(
        moodViewModel.musicGenres,
        moodViewModel.recommendedMood,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicViewModel = Provider.of<MusicViewModel>(context);
    final moodViewModel = Provider.of<MoodViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommended Music',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (moodViewModel.currentMood != null && moodViewModel.emotionAnalysis != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Show mood analysis',
              onPressed: () {
                setState(() {
                  showAnalysis = !showAnalysis;
                });
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg/home_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isInitialLoading
            ? _buildLoadingView()
            : moodViewModel.currentMood == null
            ? _buildMoodRecordingPrompt(context, moodViewModel)
            : _buildMusicContent(context, musicViewModel, moodViewModel),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Loading your personalized music...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodRecordingPrompt(BuildContext context, MoodViewModel moodViewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.mood_bad,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Please record your mood first',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'We need to know how you\'re feeling\nto recommend the perfect music for you',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              // Navigate to the mood tracker page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MoodSelectionPage(userId: '',)),
              ).then((_) async {
                // When returning from mood selection, reload data
                setState(() {
                  _isInitialLoading = true;
                });
                await _loadData();
                setState(() {
                  _isInitialLoading = false;
                });
              });
            },
            child: const Text(
              'Record My Mood',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          if (moodViewModel.lastMoodDate != null)
            Text(
              'Last recorded: ${_formatDate(moodViewModel.lastMoodDate!)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format the date nicely
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMusicContent(
      BuildContext context,
      MusicViewModel musicViewModel,
      MoodViewModel moodViewModel
      ) {
    return Column(
      children: [
        // Show emotion analysis
        if (showAnalysis && moodViewModel.emotionAnalysis != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on your mood: ${moodViewModel.currentMood?.moodType ?? "unknown"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  moodViewModel.emotionAnalysis!['contentGoal'] ??
                      'Here are some music tracks to match your mood',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

        // Display music player if a track is selected
        if (musicViewModel.selectedTrack != null)
          MusicPlayerWidget(
            track: musicViewModel.selectedTrack!,
            isPlaying: musicViewModel.isPlaying,
            onTogglePlayback: () {
              musicViewModel.togglePlayback();
            },
            onClose: () {
              musicViewModel.clearSelectedTrack();
            },
          ),

        // Music grid with pagination and pull-to-refresh
        Expanded(
          child: musicViewModel.isLoading && musicViewModel.tracks.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : musicViewModel.errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  musicViewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    musicViewModel.clearError();
                    setState(() {
                      _isInitialLoading = true;
                    });
                    await _loadData();
                    setState(() {
                      _isInitialLoading = false;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          )
              : musicViewModel.tracks.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Empty state illustration
                  Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  // Clear, informative heading
                  const Text(
                    'No music available',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Helpful explanation text
                  const Text(
                    'We couldn\'t find any music tracks that match your current mood.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary action button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        _isInitialLoading = true;
                      });
                      await _loadData();
                      setState(() {
                        _isInitialLoading = false;
                      });
                    },
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Secondary action - update mood
                  TextButton.icon(
                    icon: const Icon(Icons.mood),
                    label: const Text('Update your mood'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MoodSelectionPage(userId: '',)),
                      ).then((_) async {
                        setState(() {
                          _isInitialLoading = true;
                        });
                        await _loadData();
                        setState(() {
                          _isInitialLoading = false;
                        });
                      });
                    },
                  ),
                ],
              ),
            ),
          )
              : MusicRecommendationGrid(
            tracks: musicViewModel.tracks,
            onTrackSelected: (track) {
              musicViewModel.selectTrack(track);
            },
            onLoadMore: () {
              musicViewModel.loadMoreTracks();
            },
            onRefresh: () async {
              setState(() {
                _isInitialLoading = true;
              });
              await _loadData();
              setState(() {
                _isInitialLoading = false;
              });
              return;
            },
            isLoadingMore: musicViewModel.isLoadingMore,
            hasMoreItems: musicViewModel.hasMoreTracks,
          ),
        ),
      ],
    );
  }
}