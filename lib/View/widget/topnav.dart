import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../diary_browse.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/diaryBrowse_viewmodel.dart';
import '../diary_home.dart';
import 'package:seek_here/View/widget/logo_widget.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import '../diary_draft.dart';

class TopNavWrapper extends StatefulWidget {
  final String currentUserId;

  const TopNavWrapper({super.key, required this.currentUserId});

  @override
  _TopNavWrapperState createState() => _TopNavWrapperState();
}

class _TopNavWrapperState extends State<TopNavWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      // Draft: navigate to new page instead of switching tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryDraftScreen(currentUserId: widget.currentUserId),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget topNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    Color iconColor = isSelected ? Colors.white : Colors.black87;
    Color bgColor = isSelected
        ? const Color.fromARGB(255, 72, 87, 247).withValues(alpha: 0.7)
        : Colors.grey.shade200;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.aDLaMDisplay(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget get selectedPage {
    switch (_selectedIndex) {
      case 0:
        return DiaryHomeScreen(currentUserId: widget.currentUserId);
      case 1:
        return ChangeNotifierProvider(
          create: (_) => BrowseViewModel()..loadPublicEntries(),
          child: BrowseView(currentUserId: widget.currentUserId),
        );
      default:
        return const Center(child: Text('Unknown Page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: WHGetter.sy(context, 10)),
                child: const LogoWidget(),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  topNavItem(Icons.book, "My Diary", 0),
                  topNavItem(Icons.group, "Browse", 1),
                  topNavItem(Icons.edit, "Draft", 2),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: selectedPage,
            ),
          ],
        ),
      ),
    );
  }
}
