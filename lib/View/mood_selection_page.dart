import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/reason_selection_page.dart';

class MoodSelectionPage extends StatefulWidget {
  const MoodSelectionPage({super.key, required String userId});

  @override
  State<MoodSelectionPage> createState() => _MoodSelectionPageState();
}

class _MoodSelectionPageState extends State<MoodSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  // List of moods from Firebase
  List<String> _moods = [];

  // Selected mood
  String _selectedMood = '';

  // Text controller for custom mood input
  final TextEditingController _customMoodController = TextEditingController();

  // Show custom mood input
  bool _showCustomMoodInput = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchMoods();
  }

  // Get current user ID
  void _getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    } else {
      // Handle case where user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not logged in. Please log in to record your mood.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _customMoodController.dispose();
    super.dispose();
  }

  // Fetch moods from Firebase
  Future<void> _fetchMoods() async {
    try {
      final DocumentSnapshot snapshot =
          await _firestore.collection('app_data').doc('moods').get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('list') && data['list'] is List) {
          setState(() {
            _moods = List<String>.from(data['list']);
          });
        } else {
          // If no moods are stored, use default moods
          _setDefaultMoods();
        }
      } else {
        // If document doesn't exist, create it with default moods
        _setDefaultMoods();
      }
    } catch (e) {
      // Use default moods in case of error
      _setDefaultMoods();
    }
  }

  // Set default moods and save to Firebase if needed
  void _setDefaultMoods() async {
    final defaultMoods = [
      'Happy',
      'Bored',
      'Love',
      'Surprised',
      'Angry',
      'Sad',
      'Hopeless',
      'Jealous',
      'Anxious',
      'Overwhelmed',
      'Confused',
    ];

    setState(() {
      _moods = defaultMoods;
    });

    // Save default moods to Firebase
    try {
      await _firestore.collection('app_data').doc('moods').set({
        'list': defaultMoods,
      });
    } catch (e) {
      print('Error setting default moods: $e');
    }
  }

  // Continue to reason selection
  void _continueToReasonSelection() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not logged in. Please log in to record your mood.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final String finalMood =
        _showCustomMoodInput
            ? _customMoodController.text.trim()
            : _selectedMood;

    if (finalMood.isEmpty) {
      // Show error message if no mood is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood or enter a custom one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add custom mood to Firebase if it's a new one
    if (_showCustomMoodInput &&
        !_moods.contains(finalMood) &&
        finalMood.isNotEmpty) {
      _moods.add(finalMood);
      _firestore
          .collection('app_data')
          .doc('moods')
          .update({'list': _moods})
          .catchError((error) => print('Failed to add custom mood: $error'));
    }

    // Navigate to reason selection page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReasonSelectionPage(
          selectedMood: finalMood,
          userId: _userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double w = WHGetter.getWidth(context);
    double h = WHGetter.getHeight(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: -2,
            child: SvgPicture.asset(AppImages.bgCloud),
          ),

          
          // logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: WHGetter.sy(context, 50)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      Padding(padding: const EdgeInsets.only(left: 38.0)),

                      // Logo in the center
                      LogoWidget(),

                      // Empty container with the same width as the back button
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: SizedBox(width: 40, height: 40),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
           

          // Main content
          Positioned.fill(
            top: h * 0.15,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: Column(
                children: [
                  // Mood title
                  Text(
                    'Mood',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Mood question
                  Text(
                    'What is your mood my Dear?',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Select an emotion to represent your mood',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  // Mood options grid
                  Wrap(
                    spacing: 10,
                    runSpacing: 15,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._moods.map((mood) => _buildMoodButton(mood)),
                      // "Other" option
                      _buildMoodButton('Other'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Custom mood input field (shown when "Other" is selected)
                  if (_showCustomMoodInput)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _customMoodController,
                        decoration: InputDecoration(
                          hintText: 'Enter your mood',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      // Cancel button
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.aDLaMDisplay(),
                        ),
                      ),
                      // Continue button
                      ElevatedButton(
                        onPressed: _continueToReasonSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.aDLaMDisplay(),
                        ),
                      ),

                      
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a mood selection button
  Widget _buildMoodButton(String mood) {
    final bool isSelected = _selectedMood == mood;
    final bool isOther = mood == 'Other';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
          _showCustomMoodInput = isOther;

          // Clear custom mood when selecting a predefined mood
          if (!isOther) {
            _customMoodController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? CustomColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? CustomColors.blue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          mood,
          style: GoogleFonts.aDLaMDisplay(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}