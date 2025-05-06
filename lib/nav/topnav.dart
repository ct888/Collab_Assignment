import 'package:flutter/material.dart';
import '../view/diary_draft.dart';
import '../view/diary_browse.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diaryBrowse_viewmodel.dart';
import '../viewmodel/diaryDraft.dart';
import '../viewmodel/diary_home_viewmodel.dart';
import '../view/diary_home.dart';

class TopNavWrapper extends StatefulWidget {
  final String currentUserId;

  const TopNavWrapper({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _TopNavWrapperState createState() => _TopNavWrapperState();
}

class _TopNavWrapperState extends State<TopNavWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget topNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (label == "Draft") {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DiaryDraftScreen()),
          );
        } else if (label == "My Diary") {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DiaryHomeScreen(currentUserId: widget.currentUserId)),
          );
        } else {
          _onItemTapped(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 30,
            color: isSelected ? Colors.blueAccent : Colors.black,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget get selectedPage {
    final currentUserId = widget.currentUserId;

    switch (_selectedIndex) {
      case 0:
        return DiaryHomeScreen(currentUserId: currentUserId); // 传递给 DiaryHomeContent
      case 1:
        return ChangeNotifierProvider(
          create: (_) => BrowseViewModel()..loadPublicEntries(),
          child: BrowseView(currentUserId: currentUserId), // 继续传递给 BrowseView
        );
      default:
        return Center(child: Text('Unknown Page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.arrow_back, color: Colors.black),
                  Text(
                    "Seek Here",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(Icons.search, color: Colors.black),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  topNavItem(Icons.book, "My Diary", 0),
                  topNavItem(Icons.explore, "Browse", 1),
                  topNavItem(Icons.edit, "Draft", -1),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Main content
            Expanded(
              child: selectedPage,
            ),
          ],
        ),
      ),
    );
  }
}
