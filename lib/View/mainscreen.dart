import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seek_here/View/boa.dart';
import 'package:seek_here/View/mood_dashboard_page.dart';
import 'package:seek_here/View/recommender_screen.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/progress_meter_view.dart';
import 'package:seek_here/View/utils/navbar_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;

  final List<Widget> _pages = [
    BOA(),
    RecommenderScreen(userId: FirebaseAuth.instance.currentUser!.uid),
    MoodDashboardPage(),
    BOA(),
    ProgressMeter(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: HomeNavbarWidget(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
