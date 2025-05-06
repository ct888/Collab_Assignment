import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/mood_selection_page.dart';

import '../utils/bottom_navigation_bar.dart';

class MoodDashboardPage extends StatefulWidget {
  const MoodDashboardPage({super.key});

  @override
  State<MoodDashboardPage> createState() => _MoodDashboardPageState();
}

class _MoodDashboardPageState extends State<MoodDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Selected day from weekly view (SU, M, T, etc.)
  String? _selectedDay;
  
  // Selected date
  DateTime _selectedDate = DateTime.now();
  
  // Map to store daily moods
  Map<String, Map<String, dynamic>> _weeklyMoods = {};
  
  // Day abbreviations
  final List<String> _weekDays = ['SU', 'M', 'T', 'W', 'TH', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    // Initially no day is selected
    _selectedDay = null;
    _fetchWeeklyMoods();
  }

  // Fetch the mood entries for the current week
  Future<void> _fetchWeeklyMoods() async {
    // Calculate the start of the week (Sunday)
    DateTime startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    
    try {
      // Fetch all mood entries for the current week
      final QuerySnapshot snapshot = await _firestore
          .collection('moods')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(startOfWeek.add(const Duration(days: 6))))
          .get();

      Map<String, Map<String, dynamic>> weeklyMoods = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = data['date'] as Timestamp;
        final DateTime date = timestamp.toDate();
        final String dayOfWeek = _weekDays[date.weekday % 7];
        
        weeklyMoods[dayOfWeek] = {
          'mood': data['mood'],
          'reasons': data['reasons'],
          'date': date,
        };
      }

      setState(() {
        _weeklyMoods = weeklyMoods;
      });
    } catch (e) {
      print('Error fetching weekly moods: $e');
    }
  }

  // Update selected date and fetch moods
  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedDay = _weekDays[date.weekday % 7];
    });
    _fetchWeeklyMoods();
  }

  @override
  Widget build(BuildContext context) {
    double w = WHGetter.width(context);
    double h = WHGetter.height(context);

    // Calculate the date for the selected day (only when a day is selected)
    String formattedSelectedDate = '';
    bool hasSelectedDayData = false;
    
    if (_selectedDay != null) {
      final DateTime startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      final int selectedDayIndex = _weekDays.indexOf(_selectedDay!);
      final DateTime selectedDayDate = startOfWeek.add(Duration(days: selectedDayIndex));
      formattedSelectedDate = DateFormat('MMMM d, yyyy').format(selectedDayDate);
      
      // Check if we have mood data for the selected day
      hasSelectedDayData = _weeklyMoods.containsKey(_selectedDay);
    }

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
                  CustomColors.white,
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
              height: h * 0.12,
              decoration: BoxDecoration(
                color: CustomColors.blue.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Back button and logo with clickable functionality
          Positioned(
            top: h * 0.05,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Reset to show all days when clicking on the logo
                  setState(() {
                    _selectedDay = null;
                  });
                },
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
          ),

          // Main content
          Positioned.fill(
            top: h * 0.15,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  

                  // Conditional rendering based on whether a day is selected
                  if (_selectedDay != null) 
                    // Selected day's mood card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Your Mood on ${_selectedDay!}',
                            style: GoogleFonts.aDLaMDisplay(
                              fontSize: 20,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formattedSelectedDate,
                            style: GoogleFonts.aDLaMDisplay(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          hasSelectedDayData
                              ? Column(
                                  children: [
                                    Text(
                                      'Mood: ${_weeklyMoods[_selectedDay!]!['mood']}',
                                      style: GoogleFonts.aDLaMDisplay(
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    if (_weeklyMoods[_selectedDay!]!['reasons'] != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Reasons:',
                                            style: GoogleFonts.aDLaMDisplay(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...((_weeklyMoods[_selectedDay!]!['reasons'] as List).map((reason) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 5),
                                              child: Text(
                                                '• $reason',
                                                style: GoogleFonts.aDLaMDisplay(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      ),
                                  ],
                                )
                              : Text(
                                  'No mood recorded for this day',
                                  style: GoogleFonts.aDLaMDisplay(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                        ],
                      ),
                    )
                  else
                    // Grid view of all 7 days 
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: 7, // Display 7 mood cards for the week
                      itemBuilder: (context, index) {
                        final String dayOfWeek = _weekDays[index];
                        final bool hasData = _weeklyMoods.containsKey(dayOfWeek);
                        
                        // Calculate the date for this day
                        final DateTime startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
                        final DateTime dayDate = startOfWeek.add(Duration(days: index));
                        final String formattedDate = DateFormat('MMMM d, yyyy').format(dayDate);
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedDate,
                                style: GoogleFonts.aDLaMDisplay(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Mood: ${hasData ? _weeklyMoods[dayOfWeek]!['mood'] : 'N/A'}',
                                style: GoogleFonts.aDLaMDisplay(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (hasData && _weeklyMoods[dayOfWeek]!['reasons'] != null)
                                Expanded(
                                  child: Text(
                                    'Reason: ${(_weeklyMoods[dayOfWeek]!['reasons'] as List).join(", ")}',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 25),
                  
                  // "Your Mood on" text and date picker
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Mood on',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CustomColors.grayDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            
                            if (picked != null && picked != _selectedDate) {
                              _updateSelectedDate(picked);
                            }
                          },
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: TextStyle(color: CustomColors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  
                  // Day selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _weekDays.map((day) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDay = day;
                          });
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: _selectedDay == day 
                                ? Colors.black87 
                                : Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: _selectedDay == day 
                                    ? Colors.white 
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Record daily mood button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MoodSelectionPage(),
                          ),
                        ).then((_) {
                          // Refresh data when coming back from mood selection
                          _fetchWeeklyMoods();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Record my daily mood',
                        style: GoogleFonts.aDLaMDisplay(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 1,  // Mood tab selected
      ),
    );
  }
}