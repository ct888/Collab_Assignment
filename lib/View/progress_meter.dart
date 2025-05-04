import 'package:flutter/material.dart';
import 'package:seek_here/View/recap_report1.dart';
import 'dart:math';
import 'dart:async'; // Add this for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Model class for activities with improved error handling
class UserActivity {
  final String activity;
  final DateTime timestamp;
  final int pointsAdded;

  UserActivity({
    required this.activity,
    required this.timestamp,
    required this.pointsAdded,
  });

  // Factory to create from Firestore data with better error handling
  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle timestamp that might be null (still processing on server)
    final timestamp = data['timestamp'];
    final DateTime date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.now(); // Fallback to current time
    
    return UserActivity(
      activity: data['activity'] ?? 'Unknown activity',
      timestamp: date,
      pointsAdded: (data['pointsAdded'] ?? 0),
    );
  }
}

// Generic record class that can handle all record types
class RecordEntry {
  final DateTime timestamp;
  final String recordType;
  final Map<String, dynamic> data;
  
  RecordEntry({
    required this.timestamp,
    required this.recordType,
    required this.data,
  });
  
  // Add static map with point values for each activity type
  static const Map<String, int> pointValues = {
    'mood': 10,
    'quote': 5,
    'diary': 10,
    'recommender': 5,
    'unknown': 1, // Default value
  };
  
  // Factory to create from Firestore data
  factory RecordEntry.fromFirestore(DocumentSnapshot doc, String type) {
    Map<String, dynamic> docData = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle timestamp that might be null - check various field names
    final timestamp = docData['date'];
    final DateTime date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.now(); // Fallback to current time
    
    return RecordEntry(
      timestamp: date,
      recordType: type,
      data: docData,
    );
  }
  
  // Convert to activity-like display
  UserActivity toActivity() {
    String activityText;
    
    // Set the activity text based on record type
    switch (recordType) {
      case 'mood':
        activityText = "Recorded Mood";
        break;
      case 'quote':
        activityText = "Requested Quote";
        break;
      case 'diary':
        activityText = "Wrote Diary";
        break;
      case 'recommender':
        activityText = "Requested Recommender";
        break;
      default:
        activityText = "Unknown Activity";
    }
    
    // Get points from the static map
    int points = pointValues[recordType] ?? pointValues['unknown']!;
    
    return UserActivity(
      activity: activityText,
      timestamp: timestamp,
      pointsAdded: points,
    );
  }
  
  // Static method to get points for a specific record type
  static int getPointsForType(String recordType) {
    return pointValues[recordType] ?? pointValues['unknown']!;
  }
}

const int totalPoints = 500;

// List of motivational prompts
final List<String> motivationalPrompts = [
  'Keep going! You can do it!',
  'You\'re making great progress!',
  'Every step counts, keep moving forward!',
  'Believe in yourself, you\'re amazing!',
  'Small steps lead to big changes!',
  'Your journey matters, stay focused!',
  'You\'re stronger than you think!',
  'Progress over perfection!',
  'Today is a new opportunity!',
  'One day at a time, you got this!',
  'Stay positive, stay motivated!',
  'You are capable of amazing things!',
  'Keep pushing, you\'re almost there!',
  'Success is a journey, not a destination!',
  'Every effort counts, keep it up!',
  'You are on the right track!',
  'Your hard work will pay off!',
  'Stay committed to your goals!',
  'You are making a difference!',
  'Keep striving for greatness!'
];

class ProgressMeter extends StatefulWidget {
  const ProgressMeter({super.key});

  @override
  State<ProgressMeter> createState() => _ProgressMeterState();
}

class _ProgressMeterState extends State<ProgressMeter> {
  String currentPrompt = '';
  final Random _random = Random();
  
  List<UserActivity> userActivities = [];
  bool isLoading = true;
  StreamSubscription<QuerySnapshot>? _activitiesSubscription;
  int userPoints = 0;
  
  // Store all record types in a single map
  Map<String, List<RecordEntry>> userRecords = {
    'mood': [],
    'quote': [],
    'diary': [],
    'recommender': [],
  };
  
  Map<String, bool> isLoadingRecords = {
    'mood': true,
    'quote': true,
    'diary': true,
    'recommender': true,
  };
  
  Map<String, StreamSubscription<QuerySnapshot>?> recordSubscriptions = {
    'mood': null,
    'quote': null,
    'diary': null,
    'recommender': null,
  };
  
  List<dynamic> combinedActivities = []; // Will hold displayed activities
  List<dynamic> allActivities = []; // Will hold all activities
  bool showAllActivities = false; // Track if we're showing all activities

  @override
  void initState() {
    super.initState();
    currentPrompt = _getRandomPrompt();
    _listenForActivities();
    
    // Initialize data from Firebase
    _fetchAllRecordTypes();
  }
  
  // New method to fetch all record types at once
  void _fetchAllRecordTypes() {
    final recordTypes = [
      {'name': 'mood', 'collection': 'moods', 'orderBy': 'date'},
      {'name': 'quote', 'collection': 'quote', 'orderBy': 'date'},
      {'name': 'diary', 'collection': 'diary', 'orderBy': 'date'},
      {'name': 'recommender', 'collection': 'recommender', 'orderBy': 'date'},
    ];
    
    for (var type in recordTypes) {
      _fetchRecordsGeneric(
        type['collection'] as String,
        type['orderBy'] as String,
        type['name'] as String,
        (data, isLoading) {
          setState(() {
            userRecords[type['name'] as String] = data;
            isLoadingRecords[type['name'] as String] = isLoading;
            _updateCombinedActivities();
          });
        },
        recordSubscriptions[type['name'] as String],
        (sub) => recordSubscriptions[type['name'] as String] = sub
      );
    }
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions
    _activitiesSubscription?.cancel();
    recordSubscriptions.forEach((_, subscription) => subscription?.cancel());
    super.dispose();
  }
  
  // Method to listen for activities from Firebase - Remove the limit(5)
  void _listenForActivities() {
    setState(() {
      isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Remove the limit(5) to get all activities
      final activitiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('activities')
          .orderBy('timestamp', descending: true);
      
      // Use stream for real-time updates
      _activitiesSubscription = activitiesRef.snapshots().listen(
        (querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            setState(() {
              userActivities = querySnapshot.docs
                  .map((doc) => UserActivity.fromFirestore(doc))
                  .toList();
              
              // Simplify activity descriptions to match the 4 main categories
              for (var i = 0; i < userActivities.length; i++) {
                final activity = userActivities[i].activity.toLowerCase();
                
                if (activity.contains('quote')) {
                  userActivities[i] = UserActivity(
                    activity: 'Requested Quote',
                    timestamp: userActivities[i].timestamp,
                    pointsAdded: userActivities[i].pointsAdded
                  );
                } else if (activity.contains('recommend')) {
                  userActivities[i] = UserActivity(
                    activity: 'Requested Recommender',
                    timestamp: userActivities[i].timestamp,
                    pointsAdded: userActivities[i].pointsAdded
                  );
                } else if (activity.contains('diary')) {
                  userActivities[i] = UserActivity(
                    activity: 'Wrote Diary',
                    timestamp: userActivities[i].timestamp,
                    pointsAdded: userActivities[i].pointsAdded
                  );
                } else if (activity.contains('mood')) {
                  userActivities[i] = UserActivity(
                    activity: 'Recorded Mood',
                    timestamp: userActivities[i].timestamp,
                    pointsAdded: userActivities[i].pointsAdded
                  );
                }
              }
              
              // Calculate total points
              _calculateTotalPoints(user.uid);
              // Update combined activities
              _updateCombinedActivities();
            });
          } else {
            setState(() {
              userActivities = [];
              isLoading = false;
              // Update combined activities
              _updateCombinedActivities();
            });
          }
        },
        onError: (error) {
          debugPrint('Error getting activities: $error');
          setState(() {
            isLoading = false;
            // Show only data fetch error, not authentication error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching activity data: $error'))
            );
          });
        }
      );
    } catch (e) {
      debugPrint('Error in _listenForActivities: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Calculate total points - Simplified assuming user is logged in
  Future<void> _calculateTotalPoints(String userId) async {
    try {
      final pointsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities');
      
      final pointsSnapshot = await pointsRef.get();
      
      // Sum up all points
      int totalUserPoints = 0;
      for (var doc in pointsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        totalUserPoints += (data['pointsAdded'] as num? ?? 0).toInt();
      }
      
      setState(() {
        userPoints = totalUserPoints;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error calculating total points: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Update to fetch all records from Firebase
  void _fetchRecordsGeneric(
    String collectionName,
    String orderByField,
    String recordType,
    void Function(List<RecordEntry>, bool) updateState,
    StreamSubscription<QuerySnapshot>? currentSubscription,
    void Function(StreamSubscription<QuerySnapshot>?) updateSubscription,
  ) {
    // Set loading state to true
    updateState([], true);
    
    try {
      // Remove limit(5) to get all records
      final collectionRef = FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy(orderByField, descending: true);
      
      // Listen for data
      final subscription = collectionRef.snapshots().listen(
        (querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final data = querySnapshot.docs
                .map((doc) => RecordEntry.fromFirestore(doc, recordType))
                .toList();
            updateState(data, false);
          } else {
            // If no data in root collection, try user-specific collection
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // Remove limit(5) to get all records from user collection
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection(collectionName)
                  .orderBy(orderByField, descending: true)
                  .get()
                  .then((snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  final data = snapshot.docs
                      .map((doc) => RecordEntry.fromFirestore(doc, recordType))
                      .toList();
                  updateState(data, false);
                } else {
                  updateState([], false);
                }
              }).catchError((error) {
                debugPrint('Error getting $collectionName: $error');
                updateState([], false);
              });
            } else {
              updateState([], false);
            }
          }
        },
        onError: (error) {
          debugPrint('Error getting $collectionName: $error');
          updateState([], false);
        }
      );
      
      // Update the subscription
      updateSubscription(subscription);
    } catch (e) {
      debugPrint('Error in _fetchRecordsGeneric for $collectionName: $e');
      updateState([], false);
    }
  }
  
  // Updated method to combine activities and calculate points
  void _updateCombinedActivities() {
    List<dynamic> combined = [];
    int calculatedPoints = 0; // Reset points counter
    
    // Add regular activities and sum points
    for (var activity in userActivities) {
      combined.add(activity);
      calculatedPoints += activity.pointsAdded;
    }
    
    // Add all record types and sum points
    userRecords.forEach((type, records) {
      for (var record in records) {
        final activity = record.toActivity();
        combined.add(activity);
        calculatedPoints += activity.pointsAdded;
      }
    });
    
    // Sort by timestamp, newest first
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    setState(() {
      allActivities = List.from(combined); // Store all activities
      
      // Decide whether to show all or just the first 5
      combinedActivities = showAllActivities || combined.length <= 5 
          ? combined 
          : combined.sublist(0, 5);
      
      userPoints = calculatedPoints; // This includes points from ALL activities
    });
  }
  
  // Toggle between showing all activities and just the top 5
  void _toggleShowAllActivities() {
    setState(() {
      showAllActivities = !showAllActivities;
      
      // Update displayed activities based on the toggle state
      combinedActivities = showAllActivities || allActivities.length <= 5 
          ? allActivities 
          : allActivities.sublist(0, 5);
    });
  }
  
  // Get a random prompt from the list
  String _getRandomPrompt() {
    int index = _random.nextInt(motivationalPrompts.length);
    return motivationalPrompts[index] != currentPrompt 
        ? motivationalPrompts[index]
        : _getRandomPrompt(); // Try again if same as current
  }
  
  // Change the prompt
  void _refreshPrompt() {
    setState(() {
      currentPrompt = _getRandomPrompt();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get device size for responsive design
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg/ProgressMeterBg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          // Remove the Stack, we don't need it anymore
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.01,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  
                  SizedBox(height: screenHeight * 0.02),
                  
                  _buildMotivationalCard(context),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  _buildProgressCircle(context),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  _buildActivitiesSection(context),
                  
                  // Add spacing between activities and button
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Place View Recap button here, after the activities
                  _buildViewRecapButton(context),
                  
                  // Add bottom padding for scrolling
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double iconSize = size.width * 0.1; // 10% of screen width
    
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFBBBDC6),
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            _buildAppTitle(context),
            const Spacer(),
          ],
        ),
        SizedBox(height: size.height * 0.02),
        const Center(
          child: Text(
            'Progress Meter',
            style: TextStyle(
              color: Color(0xFF3F414E),
              fontSize: 24,
              fontFamily: 'ADLaM Display',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppTitle(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double outerCircleSize = size.width * 0.075; // 7.5% of screen width
    // final double innerCircleSize = outerCircleSize * 0.4; // 40% of outer circle
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Seek',
          style: TextStyle(
            color: Color(0xFF3F414E),
            fontSize: 16,
            fontFamily: 'ADLaM Display',
            fontWeight: FontWeight.w400,
            letterSpacing: 3.84,
          ),
        ),
        SizedBox(width: size.width * 0.015),
        Image.asset(
          'assets/logo.png',
          width: outerCircleSize,
          height: outerCircleSize,
          fit: BoxFit.contain,
        ),
        SizedBox(width: size.width * 0.015),
        const Text(
          'Here',
          style: TextStyle(
            color: Color(0xFF3F414E),
            fontSize: 16,
            fontFamily: 'ADLaM Display',
            fontWeight: FontWeight.w400,
            letterSpacing: 3.84,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalCard(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double cardHeight = size.height * 0.12; // 12% of screen height
    final double refreshIconSize = size.width * 0.1; // 10% of screen width
    
    return Container(
      width: double.infinity,
      height: cardHeight,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF8E97FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Motivational Prompt',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  currentPrompt,
                  style: const TextStyle(
                    color: Color(0xFF464A55),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.55,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refreshPrompt,
            child: Container(
              width: refreshIconSize,
              height: refreshIconSize,
              decoration: const BoxDecoration(
                color: Color(0xFF3F414E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the progress circle to use the calculated points
  Widget _buildProgressCircle(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double circleSize = size.width * 0.4; // 40% of screen width
    final double strokeWidth = size.width * 0.04; // 4% of screen width
    
    return Center(
      child: SizedBox(
        width: circleSize,
        height: circleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: CircularProgressIndicator(
                value: (userPoints / totalPoints).clamp(0.0, 1.0), // Ensure value is between 0 and 1
                backgroundColor: const Color(0xFFD0D2FF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
                strokeWidth: strokeWidth,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Goal icon added above the text
                Image.asset(
                  'assets/icon/Icon-Goal.png',
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                  color: const Color(0xFF8E97FD),
                ),
                SizedBox(height: size.height * 0.008),
                Text(
                  'Progress Meter Points',
                  style: TextStyle(
                    color: const Color(0xFF525252),
                    fontSize: size.width * 0.025, // 2.5% of screen width
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w400,
                    height: 1.60,
                    letterSpacing: 0.40,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                    '$userPoints of $totalPoints', // Use userPoints instead of points
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF262626),
                    fontSize: size.width * 0.03, // 3% of screen width
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                    letterSpacing: -0.40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    // Check if any record type is still loading
    bool isAnyLoading = isLoading || isLoadingRecords.values.any((loading) => loading);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activities done: ',
          style: TextStyle(
            color: const Color(0xFF525252),
            fontSize: size.width * 0.035,
            fontFamily: 'Lato',
            fontWeight: FontWeight.w500,
            height: 1.61,
            letterSpacing: -0.28,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: isAnyLoading
              ? _buildLoadingIndicator()
              : combinedActivities.isNotEmpty
                  ? _buildCombinedList(context)
                  : _buildNoActivitiesMessage(context),
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  // New method to display the message when there are no activities
  Widget _buildNoActivitiesMessage(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.03
      ),
      child: Center(
        child: Text(
          "You have not interacted with the system yet",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF525252),
            fontSize: size.width * 0.035,
            fontFamily: 'Lato',
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ),
      ),
    );
  }
  
  // Extract the activities list into its own method
  Widget _buildCombinedList(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Column(
      children: [
        // Header row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.015
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Activity Type',
                  style: TextStyle(
                    color: const Color(0xFF525252),
                    fontSize: size.width * 0.025,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    height: 1.60,
                    letterSpacing: 0.40,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Time',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF525252),
                    fontSize: size.width * 0.025,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    height: 1.60,
                    letterSpacing: 0.40,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Points',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF525252),
                    fontSize: size.width * 0.025,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    height: 1.60,
                    letterSpacing: 0.40,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1, color: Color(0xFFC2C2C2)),
        
        // Activity rows
        ...combinedActivities.map((item) {
          final String formattedDate = _formatDateTime(item.timestamp);
          return Column(
            children: [
              _buildActivityRow(
                context, 
                item.activity, 
                formattedDate, 
                '+ ${item.pointsAdded}'
              ),
              const Divider(height: 1, color: Color(0xFFC2C2C2)),
            ],
          );
        }).toList(),
        
        // Show More/Less button if there are more than 5 activities
        if (allActivities.length > 5)
          Center(
            child: TextButton(
              onPressed: _toggleShowAllActivities,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8E97FD),
              ),
              child: Text(
                showAllActivities ? 'Show Less' : 'Show More',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityRow(BuildContext context, String activity, String time, String points) {
    final Size size = MediaQuery.of(context).size;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04, 
        vertical: size.height * 0.01
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              activity,
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.025,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                height: 1.60,
                letterSpacing: 0.40,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.025,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                height: 1.60,
                letterSpacing: 0.40,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              points,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.025,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                height: 1.60,
                letterSpacing: 0.40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format datetime
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  Widget _buildViewRecapButton(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // final bool hasEnoughPoints = userPoints >= totalPoints; // Use userPoints instead of points
    final bool hasEnoughPoints = true;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Center(
        child: ElevatedButton(
          onPressed: hasEnoughPoints 
              ? () {
                  // Pass the collected records to RecapReport1
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecapReport1(
                      preloadedRecords: userRecords,
                    )),
                  );
                } 
              : () {
                  // Show toast message for insufficient points
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insufficient progress meter!'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasEnoughPoints 
                ? const Color(0xFFBBB5F5)  // Original purple color
                : Colors.grey,             // Grey for disabled state
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(38),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08, 
              vertical: size.height * 0.015
            ),
          ),
          child: Text(
            'View Recap',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF3F414E),
              fontSize: size.width * 0.04,
              fontFamily: 'ADLaM Display',
              fontWeight: FontWeight.w400,
              height: 1.08,
              letterSpacing: 0.80,
            ),
          ),
        ),
      ),
    );
  }
}
