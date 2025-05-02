import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/mood_selection_page.dart';

class MoodDashboardPage extends StatefulWidget {
  const MoodDashboardPage({super.key});

  @override
  State<MoodDashboardPage> createState() => _MoodDashboardPageState();
}

class _MoodDashboardPageState extends State<MoodDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Selected day from weekly view (SU, M, T, etc.)
  String _selectedDay = '';
  
  // Selected date
  DateTime _selectedDate = DateTime.now();
  
  // Map to store daily moods
  Map<String, Map<String, dynamic>> _weeklyMoods = {};
  
  // Day abbreviations
  final List<String> _weekDays = ['SU', 'M', 'T', 'W', 'TH', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    // Set today as the default selected day
    _selectedDay = _weekDays[DateTime.now().weekday % 7];
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

          // Back button and logo
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood cards grid
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

                  // Date selection section
                  Text(
                    'Your Mood on',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

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

                  const SizedBox(height: 25),

                  // Date picker button
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != _selectedDate) {
                        _updateSelectedDate(picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Select date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}