import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/moodViewModel.dart';
import '../../viewmodels/videoViewModel.dart';
import '../../viewmodels/musicViewModel.dart';
import '../../views/mood_input_screen.dart';
import '../../views/video_home_page.dart';
import '../../views/music_home_page.dart';
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MoodViewModel()),
        ChangeNotifierProvider(create: (context) => VideoViewModel()),
        ChangeNotifierProvider(create: (context) => MusicViewModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Recommender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum RecommendationType { video, music }

class _HomeScreenState extends State<HomeScreen> {
  RecommendationType? _selectedType;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Recommender'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Consumer<MoodViewModel>(
            builder: (context, moodViewModel, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'What are you in the mood for?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRecommendationOption(
                        context,
                        RecommendationType.video,
                        'Videos',
                        Icons.video_library,
                      ),
                      _buildRecommendationOption(
                        context,
                        RecommendationType.music,
                        'Music',
                        Icons.music_note,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (_selectedType != null)
                    ElevatedButton(
                      onPressed:
                          _isAnalyzing
                              ? null
                              : () => _proceedWithRecommendation(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child:
                          _isAnalyzing
                              ? const CircularProgressIndicator()
                              : const Text(
                                'Find Recommendations',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  if (moodViewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        moodViewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationOption(
    BuildContext context,
    RecommendationType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _proceedWithRecommendation(BuildContext context) async {
    final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);

    // Check if mood data exists
    if (moodViewModel.currentMood == null) {
      // Navigate to mood input screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MoodInputScreen(),
      ),
    );

      if (result != true) {
        // User didn't complete the mood input
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Analyze emotion
    final success = await moodViewModel.analyzeEmotion();

    setState(() {
      _isAnalyzing = false;
    });

    if (!success) {
      return;
    }

    // Navigate to appropriate screen based on selection
    if (_selectedType == RecommendationType.video) {
      _navigateToVideoRecommendations(context);
    } else if (_selectedType == RecommendationType.music) {
      _navigateToMusicRecommendations(context);
    }
  }

  void _navigateToVideoRecommendations(BuildContext context) {
    final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);
    final videoViewModel = Provider.of<VideoViewModel>(context, listen: false);

    // Clear previous videos
    videoViewModel.clearVideos();

    // Start fetching videos
    videoViewModel.fetchRecommendedVideos(
      moodViewModel.videoCategories,
      moodViewModel.recommendedMood,
    );

    // Navigate to video screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoPlayerScreen()),
    );
  }

  void _navigateToMusicRecommendations(BuildContext context) {
    final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);
    final musicViewModel = Provider.of<MusicViewModel>(context, listen: false);

    // Clear previous tracks
    musicViewModel.clearTracks();

    // Start fetching music
    musicViewModel.fetchRecommendedTracks(
      moodViewModel.musicGenres,
      moodViewModel.recommendedMood,
    );

    // Navigate to music screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
    );
  }
}
