import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/musicViewModel.dart';
import '../../viewmodels/moodViewModel.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/recommendation_list.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({Key? key}) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  bool showAnalysis = false;

  @override
  void initState() {
    super.initState();
    // Initial load of tracks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final musicViewModel = Provider.of<MusicViewModel>(context, listen: false);
      final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);

      musicViewModel.fetchRecommendedTracks(
        moodViewModel.musicGenres,
        moodViewModel.recommendedMood,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicViewModel = Provider.of<MusicViewModel>(context);
    final moodViewModel = Provider.of<MoodViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.info_outline),
            ),
            tooltip: 'Current Mood',
            onPressed: () {
              setState(() {
                showAnalysis = !showAnalysis;
              });
            },
          ),
        ],
      ),
      body: Column(
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
                    onPressed: () {
                      musicViewModel.clearError();
                      musicViewModel.refreshTracks();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
                : musicViewModel.tracks.isEmpty
                ? const Center(child: Text('No music found'))
                : MusicRecommendationGrid(
              tracks: musicViewModel.tracks,
              onTrackSelected: (track) {
                musicViewModel.selectTrack(track);
              },
              onLoadMore: () {
                musicViewModel.loadMoreTracks();
              },
              onRefresh: () async {
                return musicViewModel.refreshTracks();
              },
              isLoadingMore: musicViewModel.isLoadingMore,
              hasMoreItems: musicViewModel.hasMoreTracks,
            ),
          ),
        ],
      ),
    );
  }
}