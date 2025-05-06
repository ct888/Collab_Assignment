import 'package:flutter/material.dart';
import 'package:seek_here/View/mood_dashboard_page.dart';
import 'package:seek_here/View/recommender_page.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) => _navigateToPage(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'BoA',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_emotions),
          label: 'Mood',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.circle),
          label: 'Recommender',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Diary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    // If we're already on the selected page, don't navigate
    if (index == currentIndex) return;
    
    // Navigate to the corresponding screen based on the index
    Widget destinationScreen;
    
    switch (index) {
      // case 0:
      //   // destinationScreen = const BoAScreen();
      //   break;
      case 1:
        destinationScreen = const MoodDashboardPage();
        break;
      case 2:
        destinationScreen = const RecommenderScreen();
        break;
      // case 3:
      //   // destinationScreen = const DiaryScreen();
      //   break;
      // case 4:
      //   // destinationScreen = const AccountScreen();
      //   break;
      default:
        return;
    }
    
    // Navigate to the destination screen, replacing the current route
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }
}