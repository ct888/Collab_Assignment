import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/View/mood_selection_page.dart';
import 'package:seek_here/ViewModel/moodViewModel.dart';
import 'package:seek_here/ViewModel/videoViewModel.dart';
import 'package:seek_here/widgets/recommendation_list.dart';
import 'package:seek_here/widgets/video_player_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key? key}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ScrollController scrollController = ScrollController();
  bool _isInitialLoading = true;
  bool showAnalysis = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(loadMoreData);

    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      setState(() {
        _isInitialLoading = false;
      });
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(loadMoreData);
    scrollController.dispose();
    super.dispose();
  }

  // Improved method to load data that can be called whenever needed
  Future<void> _loadData() async {
    final videoViewModel = Provider.of<VideoViewModel>(context, listen: false);
    final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);

    // First, fetch the mood from Firebase
    await moodViewModel.fetchLatestData("E0uSiko9ZWguiI8md0xFbOM3rHD3");

    // Only proceed if we have a mood (regardless of when it was recorded)
    if (moodViewModel.currentMood != null) {
      // Analyze emotion based on the current mood
      await moodViewModel.analyzeEmotion();

      // Then fetch video recommendations based on analysis
      await videoViewModel.fetchRecommendedVideos(
        moodViewModel.videoCategories,
        moodViewModel.recommendedMood,
      );
    }
  }

  void loadMoreData() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      final videoViewModel = Provider.of<VideoViewModel>(
        context,
        listen: false,
      );
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
      extendBodyBehindAppBar: true,
      appBar:
      videoViewModel.selectedVideo == null
          ? AppBar(
        title: const Text(
          'Recommended Videos',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
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
      )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg/home_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isInitialLoading
              ? _buildLoadingView()
              : moodViewModel.currentMood == null
              ? _buildMoodRecordingPrompt(context, moodViewModel)
              : _buildVideoContent(context, videoViewModel, moodViewModel),
        ),
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
            'Loading your personalized videos...',
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
            Icons.videocam_off,
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
            'We need to know how you\'re feeling\nto recommend the perfect videos for you',
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
                MaterialPageRoute(builder: (context) => const MoodSelectionPage()),
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

  Widget _buildVideoContent(
      BuildContext context,
      VideoViewModel videoViewModel,
      MoodViewModel moodViewModel
      ) {
    return Column(
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
            child:
            videoViewModel.isLoading
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
                    onPressed: () async {
                      videoViewModel.clearError();
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
                : videoViewModel.videos.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Empty state illustration
                    Icon(
                      Icons.video_library_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    // Clear, informative heading
                    const Text(
                      'No videos available',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Helpful explanation text
                    const Text(
                      'We couldn\'t find any videos that match your current mood.',
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
                          MaterialPageRoute(builder: (context) => const MoodSelectionPage()),
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
                : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isInitialLoading = true;
                });
                await _loadData();
                setState(() {
                  _isInitialLoading = false;
                });
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
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () {
                        if (mounted) {
                          videoViewModel.selectVideo(video);
                        }
                      },
                    );
                  } else {
                    videoViewModel.selectVideo(video);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}