import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/Model/mood.dart'; // Import UserMood model
import 'package:flutter/foundation.dart'; // For print debugging
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/mood_selection_page.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
import 'package:seek_here/ViewModel/moodViewModel.dart';
import '../utils/bottom_navigation_bar.dart';

class MoodDashboardPage extends StatefulWidget {
  const MoodDashboardPage({super.key});

  @override
  State<MoodDashboardPage> createState() => _MoodDashboardPageState();
}

class _MoodDashboardPageState extends State<MoodDashboardPage> {
  final MoodViewModel _moodViewModel =
      MoodViewModel(); // Create an instance of MoodViewModel

  // Selected day from weekly view (SU, M, T, etc.)
  String? _selectedDay;

  // Selected date
  DateTime _selectedDate = DateTime.now();

  // List to store all user moods
  List<UserMood> _allMoods = [];

  // Map to store daily moods by date string
  Map<String, UserMood> _weeklyMoods = {};

  // Day abbreviations
  final List<String> _weekDays = ['SU', 'M', 'T', 'W', 'TH', 'F', 'S'];

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initially no day is selected
    _selectedDay = null;
    _fetchAllMoods();
  }

  // Fetch all mood entries and then filter for the current week
  Future<void> _fetchAllMoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all moods using the MoodViewModel
      final moods = await _moodViewModel.fetchAllMoods();

      // Sort all moods by timestamp in descending order (most recent first)
      moods.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _allMoods = moods;
        _isLoading = false;
      });

      // Process moods for the current week
      _processWeeklyMoods();
    } catch (e) {
      print('Error fetching moods: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Process the fetched moods for the current week view
  void _processWeeklyMoods() {
    // Calculate the start of the week (Sunday)
    DateTime startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );

    // Calculate the end of the week (Saturday)
    DateTime endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    // Map to store the latest mood for each day
    Map<String, UserMood> weeklyMoods = {};

    // Group moods by date string
    Map<String, List<UserMood>> moodsByDate = {};

    if (kDebugMode) {
      print('Processing weekly moods from ${_allMoods.length} total moods');
      print('Start of week: $startOfWeek, End of week: $endOfWeek');
    }

    // Filter moods that fall within the current week
    for (var mood in _allMoods) {
      if (mood.timestamp.isAfter(
            startOfWeek.subtract(const Duration(days: 0)),
          ) &&
          mood.timestamp.isBefore(endOfWeek.add(const Duration(days: 0)))) {
        final String dateString = DateFormat(
          'yyyy-MM-dd',
        ).format(mood.timestamp);

        // Initialize list if this date doesn't exist yet
        if (!moodsByDate.containsKey(dateString)) {
          moodsByDate[dateString] = [];
        }

        // Add the mood to this date's list
        moodsByDate[dateString]!.add(mood);

        if (kDebugMode) {
          print(
            'Found mood for $dateString: ${mood.moodType} (${mood.timestamp})',
          );
        }
      }
    }

    // For each date, find the most recent mood entry
    moodsByDate.forEach((dateString, moodsList) {
      // Sort the moods by timestamp in descending order (most recent first)
      moodsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Add the most recent mood for this date to the weekly moods map
      if (moodsList.isNotEmpty) {
        weeklyMoods[dateString] = moodsList.first;
        if (kDebugMode) {
          print(
            'Selected latest mood for $dateString: ${moodsList.first.moodType} (${moodsList.first.timestamp})',
          );
        }
      }
    });

    setState(() {
      _weeklyMoods = weeklyMoods;
    });
  }

  // Update selected date and process moods
  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedDay = _weekDays[date.weekday % 7];
    });
    _processWeeklyMoods();
  }

  @override
  Widget build(BuildContext context) {
    double w = WHGetter.getWidth(context);
    double h = WHGetter.getHeight(context);

    // Calculate the date for the selected day (only when a day is selected)
    String formattedSelectedDate = '';
    bool hasSelectedDayData = false;
    UserMood? selectedDayMood;

    if (_selectedDay != null) {
      final DateTime startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday % 7),
      );
      final int selectedDayIndex = _weekDays.indexOf(_selectedDay!);
      final DateTime selectedDayDate = startOfWeek.add(
        Duration(days: selectedDayIndex),
      );
      formattedSelectedDate = DateFormat(
        'MMMM d, yyyy',
      ).format(selectedDayDate);
      final String selectedDateString = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDayDate);

      // Check if we have mood data for the selected day
      hasSelectedDayData = _weeklyMoods.containsKey(selectedDateString);
      if (hasSelectedDayData) {
        selectedDayMood = _weeklyMoods[selectedDateString];
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background container with gradient
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

          // Main content with loading state
          Positioned.fill(
            top: h * 0.19,
            child:
                _isLoading
                    ? _buildLoadingIndicator()
                    : _buildMainContent(
                      w,
                      h,
                      formattedSelectedDate,
                      hasSelectedDayData,
                      selectedDayMood,
                    ),
          ),
        ],
      ),
    );
  }

  // Loading indicator widget
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(CustomColors.blue),
          ),
          const SizedBox(height: 25),
          Text(
            'Loading your mood data...',
            style: GoogleFonts.aDLaMDisplay(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Main content widget
  Widget _buildMainContent(
    double w,
    double h,
    String formattedSelectedDate,
    bool hasSelectedDayData,
    UserMood? selectedDayMood,
  ) {
    return SingleChildScrollView(
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
                            'Mood: ${selectedDayMood!.moodType}',
                            style: GoogleFonts.aDLaMDisplay(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (selectedDayMood.notes.isNotEmpty)
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
                                ...selectedDayMood.notes.map((reason) {
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
                                }).toList(),
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
            // Grid view of all 7 days of the week
            _buildWeeklyMoodGrid(),

          const SizedBox(height: 25),

          // Date selection header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = null;
                    });
                  },
                  child: Text(
                    'Your Mood on',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.grayDark,
                    ),
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
            children:
                _weekDays.map((day) {
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
                        color:
                            _selectedDay == day
                                ? Colors.black87
                                : Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color:
                                _selectedDay == day
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
                    builder: (context) => const MoodSelectionPage(userId: ''),
                  ),
                ).then((_) {
                  // Refresh data when coming back from mood selection
                  _fetchAllMoods();
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
    );
  }

  // Weekly mood grid widget
  Widget _buildWeeklyMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 15,
      ),
      itemCount: 8, // We need 8 slots to place the 7th item in position 7
      itemBuilder: (context, index) {
        // Skip position 6 (row 3, column 1)
        if (index == 6) {
          return const SizedBox.shrink(); // Empty spacer
        }

        // Adjust the real data index for items
        int dataIndex;
        if (index < 6) {
          dataIndex = index; // Items 0-5 stay the same
        } else {
          dataIndex = index - 1; // Item at index 7 shows data for index 6
        }

        // Only show data if we're within the original 7 days range
        if (dataIndex >= 7) {
          return const SizedBox.shrink();
        }

        // Calculate the date for this day
        final DateTime startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday % 7),
        );
        final DateTime dayDate = startOfWeek.add(Duration(days: dataIndex));
        final String dateString = DateFormat('yyyy-MM-dd').format(dayDate);

        // Get the data for this day
        final bool hasData = _weeklyMoods.containsKey(dateString);
        final String mood =
            hasData ? _weeklyMoods[dateString]!.moodType : 'N/A';
        final List<String> reasons =
            hasData ? _weeklyMoods[dateString]!.notes : [];

        // Determine the background color based on mood (if custom styling is desired)
        Color cardColor = Colors.white;
        if (hasData) {
          // You can customize these colors based on your app's design
          switch (mood.toLowerCase()) {
            case 'happy':
              cardColor = Colors.yellow.shade50;
              break;
            case 'sad':
              cardColor = Colors.blue.shade50;
              break;
            case 'angry':
              cardColor = Colors.red.shade50;
              break;
            case 'anxious':
              cardColor = Colors.purple.shade50;
              break;
            case 'relaxed':
              cardColor = Colors.green.shade50;
              break;
            default:
              cardColor = Colors.white;
          }
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = _weekDays[dayDate.weekday % 7];
              _selectedDate = dayDate;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekDays[dayDate.weekday % 7],
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d').format(dayDate),
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  hasData ? 'Mood: $mood' : 'No mood',
                  style: GoogleFonts.aDLaMDisplay(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: hasData ? FontWeight.w500 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                if (hasData && reasons.isNotEmpty)
                  Expanded(
                    child: Text(
                      reasons.length == 1
                          ? reasons.first
                          : '${reasons.length} reasons',
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
