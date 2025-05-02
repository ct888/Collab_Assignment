import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/mood_dashboard_page.dart';

class ReasonSelectionPage extends StatefulWidget {
  final String selectedMood;

  const ReasonSelectionPage({
    super.key, 
    required this.selectedMood,
  });

  @override
  State<ReasonSelectionPage> createState() => _ReasonSelectionPageState();
}

class _ReasonSelectionPageState extends State<ReasonSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // List of reasons from Firebase
  List<String> _reasons = [];
  
  // Selected reasons (up to 3)
  List<String> _selectedReasons = [];
  
  // Text controller for custom reason input
  final TextEditingController _customReasonController = TextEditingController();
  
  // Show custom reason input
  bool _showCustomReasonInput = false;

  @override
  void initState() {
    super.initState();
    _fetchReasons();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  // Fetch reasons from Firebase
  Future<void> _fetchReasons() async {
    try {
      final DocumentSnapshot snapshot = await _firestore
          .collection('app_data')
          .doc('reasons')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('list') && data['list'] is List) {
          setState(() {
            _reasons = List<String>.from(data['list']);
          });
        } else {
          // If no reasons are stored, use default reasons
          _setDefaultReasons();
        }
      } else {
        // If document doesn't exist, create it with default reasons
        _setDefaultReasons();
      }
    } catch (e) {
      print('Error fetching reasons: $e');
      // Use default reasons in case of error
      _setDefaultReasons();
    }
  }

  // Set default reasons and save to Firebase if needed
  void _setDefaultReasons() async {
    final defaultReasons = [
      'Family', 'School', 'Travel', 'Health',
      'Weather', 'Hobbies', 'Game', 'Studies',
      'Pet'
    ];

    setState(() {
      _reasons = defaultReasons;
    });

    // Save default reasons to Firebase
    try {
      await _firestore
          .collection('app_data')
          .doc('reasons')
          .set({'list': defaultReasons});
    } catch (e) {
      print('Error setting default reasons: $e');
    }
  }

  // Toggle reason selection
  void _toggleReason(String reason) {
    setState(() {
      if (reason == 'Other') {
        _showCustomReasonInput = !_showCustomReasonInput;
        
        // If turning off custom input, remove any custom reason
        if (!_showCustomReasonInput) {
          _customReasonController.clear();
          _selectedReasons.removeWhere((r) => !_reasons.contains(r) && r != 'Other');
        }
      } else {
        if (_selectedReasons.contains(reason)) {
          _selectedReasons.remove(reason);
        } else {
          // Ensure we don't exceed 3 reasons
          if (_selectedReasons.length < 3) {
            _selectedReasons.add(reason);
          } else {
            // Show message that max reasons reached
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can select a maximum of 3 reasons.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    });
  }

  // Save the mood entry to Firebase
  Future<void> _saveMoodEntry() async {
    // Get final list of reasons
    List<String> finalReasons = List.from(_selectedReasons);
    
    // Add custom reason if provided
    final String customReason = _customReasonController.text.trim();
    if (_showCustomReasonInput && customReason.isNotEmpty && finalReasons.length < 3) {
      finalReasons.add(customReason);
      
      // Add to Firebase if it's a new reason
      if (!_reasons.contains(customReason)) {
        _reasons.add(customReason);
        _firestore
            .collection('app_data')
            .doc('reasons')
            .update({'list': _reasons})
            .catchError((error) => print('Failed to add custom reason: $error'));
      }
    }
    
    if (finalReasons.isEmpty) {
      // Show error message if no reason is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one reason.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Current date and time
    final DateTime now = DateTime.now();
    
    try {
      // Save mood entry to Firebase
      await _firestore.collection('moods').add({
        'mood': widget.selectedMood,
        'reasons': finalReasons,
        'date': Timestamp.fromDate(now),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MoodDashboardPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error saving mood: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save your mood: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = WHGetter.width(context);
    double h = WHGetter.height(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background container with gradient
          Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CustomColors.blue.withOpacity(0.8),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Top wave decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: h * 0.25,
              decoration: BoxDecoration(
                color: CustomColors.blue.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Logo at top
          Positioned(
            top: h * 0.05,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seek',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B88F9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Here',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Positioned.fill(
            top: h * 0.15,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: Column(
                children: [
                  // Reason title
                  Text(
                    'Reason',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Reason question
                  Text(
                    'What reason that causes your mood Dear?',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Subtitle
                  Text(
                    'You can select more than one reasons (maximum 3)',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Reason options grid
                  Wrap(
                    spacing: 10,
                    runSpacing: 15,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._reasons.map((reason) => _buildReasonButton(reason)),
                      // "Other" option
                      _buildReasonButton('Other'),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Custom reason input field (shown when "Other" is selected)
                  if (_showCustomReasonInput)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _customReasonController,
                        decoration: InputDecoration(
                          hintText: 'Enter your reason',
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
                      // Save button
                      ElevatedButton(
                        onPressed: _saveMoodEntry,
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
                          'Save',
                          style: GoogleFonts.aDLaMDisplay(),
                        ),
                      ),
                      
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

  // Build a reason selection button
  Widget _buildReasonButton(String reason) {
    final bool isSelected = _selectedReasons.contains(reason);
    final bool isOther = reason == 'Other';

    return GestureDetector(
      onTap: () => _toggleReason(reason),
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
          reason,
          style: GoogleFonts.aDLaMDisplay(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}