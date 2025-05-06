import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seek_here/View/utils/button_widget.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
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
  final List<String> _selectedReasons = [];
  final TextEditingController _otherReasonController = TextEditingController();
  bool _showOtherInput = false;
  bool _isLoading = true;
  List<String> _availableReasons = [];
  
  @override
  void initState() {
    super.initState();
    _loadReasons();
  }
  
  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }
  
  // Load reason options from Firebase
  Future<void> _loadReasons() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First try to get predefined reasons from a settings collection
      final reasonsDoc = await _firestore.collection('settings').doc('reasons').get();
      
      if (reasonsDoc.exists && reasonsDoc.data() != null && reasonsDoc.data()!.containsKey('options')) {
        // If we have predefined reasons, use those
        final options = reasonsDoc.data()!['options'];
        if (options is List) {
          _availableReasons = List<String>.from(options);
        }
      } else {
        // Otherwise use default reasons
        _availableReasons = [
          'Family', 'School', 'Travel', 'Health',
          'Weather', 'Hobbies', 'Game', 'Studies',
          'Pet', 'Other'
        ];
        
        // And save them to Firebase for future use
        await _firestore.collection('settings').doc('reasons').set({
          'options': _availableReasons
        });
      }
    } catch (e) {
      // If there's an error, use default reasons
      _availableReasons = [
        'Family', 'School', 'Travel', 'Health',
        'Weather', 'Hobbies', 'Game', 'Studies',
        'Pet', 'Other'
      ];
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reasons: $e'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _toggleReason(String reason) {
    setState(() {
      if (reason == 'Other') {
        _showOtherInput = !_showOtherInput;
        return;
      }
      
      if (_selectedReasons.contains(reason)) {
        _selectedReasons.remove(reason);
      } else {
        // Check if we're at the maximum of 3 reasons
        if (_selectedReasons.length < 3) {
          _selectedReasons.add(reason);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select a maximum of 3 reasons'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }
  
  Future<void> _saveMoodAndReasons() async {
    // Validate selection
    final List<String> finalReasons = List.from(_selectedReasons);
    
    // Add custom reason if applicable
    if (_showOtherInput && _otherReasonController.text.trim().isNotEmpty) {
      final customReason = _otherReasonController.text.trim();
      finalReasons.add(customReason);
      
      // Save new reason to Firebase if not already in the list
      if (!_availableReasons.contains(customReason) && customReason != 'Other') {
        _firestore.collection('settings').doc('reasons').update({
          'options': FieldValue.arrayUnion([customReason])
        }).catchError((error) {
          print('Error saving new reason: $error');
        });
      }
    }
    
    if (finalReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one reason before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Save to Firebase
      await _firestore.collection('moods').add({
        'mood': widget.selectedMood,
        'reasons': finalReasons,
        'date': Timestamp.now(),
        'day': _getCurrentDay(),
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to dashboard
      // Using pushReplacement to prevent going back to previous screens
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MoodDashboardPage()),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mood: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Get current day abbreviation
  String _getCurrentDay() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday: return 'M';
      case DateTime.tuesday: return 'T';
      case DateTime.wednesday: return 'W';
      case DateTime.thursday: return 'TH';
      case DateTime.friday: return 'F';
      case DateTime.saturday: return 'S';
      case DateTime.sunday: return 'SU';
      default: return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final double w = WHGetter.getWidth(context);
    final double h = WHGetter.getHeight(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // White background
          Container(width: w, height: h, color: CustomColors.white),
          
          // Blue curved background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * 0.35,
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors.blue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: CustomColors.white))
              : Column(
                  children: [
                    // Header with back button and logo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Expanded(
                            child: Center(
                              child: LogoWidget(),
                            ),
                          ),
                          const SizedBox(width: 48), // For balance
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Reason title
                    Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Subtitle
                    Text(
                      'What reason that causes your mood Dear?',
                      style: TextStyle(
                        fontSize: 18,
                        color: CustomColors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Instruction
                    Text(
                      'You can select more then one reasons (maximum 3)',
                      style: TextStyle(
                        fontSize: 16,
                        color: CustomColors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Reason selection grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _availableReasons.length,
                          itemBuilder: (context, index) {
                            final reason = _availableReasons[index];
                            final isSelected = reason != 'Other' && _selectedReasons.contains(reason);
                            
                            return InkWell(
                              onTap: () => _toggleReason(reason),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: CustomColors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: isSelected || (reason == 'Other' && _showOtherInput)
                                    ? Border.all(color: CustomColors.blue, width: 2)
                                    : null,
                                  boxShadow: isSelected || (reason == 'Other' && _showOtherInput)
                                    ? [BoxShadow(color: CustomColors.blue.withOpacity(0.3), blurRadius: 5)]
                                    : null,
                                ),
                                child: Center(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected || (reason == 'Other' && _showOtherInput) 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                      color: isSelected || (reason == 'Other' && _showOtherInput) 
                                        ? CustomColors.blue 
                                        : CustomColors.grayDark,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Other reason input field (conditionally shown)
                    if (_showOtherInput)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: TextField(
                          controller: _otherReasonController,
                          decoration: InputDecoration(
                            hintText: 'Enter your reason',
                            filled: true,
                            fillColor: CustomColors.grayLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                    
                    // Selected reasons summary
                    if (_selectedReasons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CustomColors.grayLight,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Reasons:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CustomColors.grayDark,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _selectedReasons.join(', '),
                                style: TextStyle(color: CustomColors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          // Save button
                          Expanded(
                            child: TextButtonWidget(
                              label: "Save",
                              onPressed: _saveMoodAndReasons,
                              height: WHGetter.sy(context, 50),
                              backgroundColor: CustomColors.blue,
                            ),
                          ),
                          
                          const SizedBox(width: 15),
                          
                          // Cancel button
                          Expanded(
                            child: TextButtonWidget(
                              label: "Cancel",
                              onPressed: () => Navigator.of(context).pop(),
                              height: WHGetter.sy(context, 50),
                              backgroundColor: CustomColors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}