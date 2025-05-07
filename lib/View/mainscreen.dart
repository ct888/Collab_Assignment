import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seek_here/View/boa.dart';
import 'package:seek_here/View/mood_dashboard_page.dart';
import 'package:seek_here/View/recommender_screen.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/navbar_widget.dart';
import 'package:seek_here/nav/topnav.dart';
import 'package:seek_here/View/account_setting.dart';

class MainScreen extends StatefulWidget {
  final String userId; // Accept userId from previous screen

  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BOA(),
      RecommenderScreen(userId: widget.userId),
      MoodDashboardPage(),
      TopNavWrapper(currentUserId: widget.userId),
      AccountSetting()
    ];
  }


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
