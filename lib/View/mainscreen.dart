import 'package:flutter/material.dart';
import 'package:seek_here/View/boa.dart';
import 'package:seek_here/View/mood_dashboard_page.dart';
import 'package:seek_here/View/utils/navbar_widget.dart';
import 'package:seek_here/views/recommender_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;

  final List<Widget> _pages = [
    BOA(),
    MoodDashboardPage(),
    RecommenderScreen(),
    BOA(),
    BOA(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: HomeNavbarWidget(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
