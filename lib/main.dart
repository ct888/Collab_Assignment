import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seekhere_proj/views/recommender_page.dart';
import '../../viewmodels/moodViewModel.dart';
import '../../viewmodels/videoViewModel.dart';
import '../../viewmodels/musicViewModel.dart';

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
      home: const RecommenderScreen(),
    );
  }
}


