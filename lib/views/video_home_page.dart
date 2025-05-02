import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/videoViewModel.dart';
import '../widgets/video_player_widget.dart';
import '../viewmodels/moodViewModel.dart';
import '../widgets/recommendation_list.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key? key}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;
  bool showAnalysis = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(loadMoreData);

    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoViewModel = Provider.of<VideoViewModel>(context, listen: false);
      final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);

      videoViewModel.fetchRecommendedVideos(
        moodViewModel.videoCategories,
        moodViewModel.recommendedMood,
      );
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(loadMoreData);
    scrollController.dispose();
    super.dispose();
  }

  void loadMoreData() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      final videoViewModel = Provider.of<VideoViewModel>(context, listen: false);
      if (!videoViewModel.isLoading && !videoViewModel.isPaginationLoading) {
        videoViewModel.loadMoreVideos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoViewModel = Provider.of<VideoViewModel>(context);
    final moodViewModel = Provider.of<MoodViewModel>(context);

    return Scaffold(
      appBar: videoViewModel.selectedVideo == null ? AppBar(
        title: const Text('Recommended Videos'),
        centerTitle: true,
        actions: [
          if (moodViewModel.emotionAnalysis != null)
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
      ): null,
      body: SafeArea(
        child: Column(
          children: [
            // Show emotion analysis
            if (showAnalysis && moodViewModel.emotionAnalysis != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
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
                          'Here are some videos to match your mood',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Display video player if a video is selected
            if (videoViewModel.selectedVideo != null)
              Expanded(
                child: SafeArea(
                  child: VideoPlayerWidget(
                    key: ValueKey(videoViewModel.selectedVideo!.videoId),
                    videoId: videoViewModel.selectedVideo!.videoId,
                    onClose: () {
                      // Clear the selected video on close
                      videoViewModel.clearSelectedVideo();
                      // Force memory cleanup
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) setState(() {});
                      });
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: videoViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : videoViewModel.errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        videoViewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          videoViewModel.clearError();
                          videoViewModel.fetchRecommendedVideos(
                            moodViewModel.videoCategories,
                            moodViewModel.recommendedMood,
                            refresh: true,
                          );
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
                    : videoViewModel.videos.isEmpty
                    ? const Center(child: Text('No videos found'))
                    : RefreshIndicator(
                  onRefresh: () async {
                    await videoViewModel.fetchRecommendedVideos(
                      moodViewModel.videoCategories,
                      moodViewModel.recommendedMood,
                      refresh: true,
                    );
                  },
                  child: VideoRecommendationList(
                    videos: videoViewModel.videos,
                    scrollController: scrollController,
                    isLoadingMore: videoViewModel.isPaginationLoading,
                    onVideoSelected: (video) {
                      // Ensure any previous video is properly disposed
                      if (videoViewModel.selectedVideo != null) {
                        videoViewModel.clearSelectedVideo();
                        // Add a small delay before setting new video
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            videoViewModel.selectVideo(video);
                          }
                        });
                      } else {
                        videoViewModel.selectVideo(video);
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}