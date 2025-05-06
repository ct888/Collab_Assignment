import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seek_here/Model/progress_meter_model.dart';
import 'package:seek_here/View/recap_report1_view.dart';
import 'package:seek_here/Service/user_records_service.dart';

// userID for testing purposes
// const String userID = 'E0uSiko9ZWguiI8md0xFbOM3rHD3';

class ActivityDisplayData {
  final String activity;
  final DateTime timestamp;
  final int pointsAdded;
  
  ActivityDisplayData({
    required this.activity,
    required this.timestamp,
    required this.pointsAdded,
  });
}

class ProgressMeterViewModel extends ChangeNotifier {
  final int totalPoints = 500;
  
  // State variables
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
  
  List<ActivityDisplayData> combinedActivities = []; // Will hold displayed activities for view
  List<ActivityDisplayData> allActivities = []; // Will hold all activities for view
  bool showAllActivities = false; // Track if we're showing all activities
  
  BuildContext? context; // Context for showing snackbars
  
  // Reference to the shared service
  final UserRecordsService _recordsService = UserRecordsService();
  
  // Constructor
  ProgressMeterViewModel() {
    currentPrompt = _getRandomPrompt();
  }
  
  // Initialize data
  void initialize(BuildContext context) {
    this.context = context;
    _listenForActivities();
    _fetchAllRecordTypes();
  }
  
  // Dispose resources
  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    recordSubscriptions.forEach((_, subscription) => subscription?.cancel());
    super.dispose();
  }

  // New method to fetch all record types at once
  void _fetchAllRecordTypes() {
    final recordTypes = [
      {'name': 'mood', 'collection': 'moods', 'orderBy': 'date'},
      {'name': 'quote', 'collection': 'quote', 'orderBy': 'date'},
      {'name': 'diary', 'collection': 'diary_entries', 'orderBy': 'date'},
      {'name': 'recommender', 'collection': 'recommender', 'orderBy': 'date'},
    ];
    
    for (var type in recordTypes) {
      _fetchRecordsGeneric(
        type['collection'] as String,
        type['orderBy'] as String,
        type['name'] as String,
        (data, isLoading) {
          userRecords[type['name'] as String] = data;
          isLoadingRecords[type['name'] as String] = isLoading;
          _updateCombinedActivities();
          notifyListeners();
        },
        recordSubscriptions[type['name'] as String],
        (sub) => recordSubscriptions[type['name'] as String] = sub
      );
    }
  }
  
  // Method to listen for activities from Firebase
  void _listenForActivities() {
    isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Get all activities
      final activitiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('activities')
          .orderBy('timestamp', descending: true);
      
      // Use stream for real-time updates
      _activitiesSubscription = activitiesRef.snapshots().listen(
        (querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            userActivities = querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data();
              
              // Extract data from the document
              String activity = data['activity'] ?? 'Unknown activity';
              
              // Handle timestamp that might be null
              final timestamp = data['timestamp'];
              final DateTime date = timestamp is Timestamp 
                  ? timestamp.toDate() 
                  : DateTime.now();
              
              int pointsAdded = (data['pointsAdded'] ?? 0);
              
              // Use the standardizer helper from the model
              return UserActivity.createStandardized(
                activity, 
                date, 
                pointsAdded
              );
            }).toList();
            
            // Calculate total points
            _calculateTotalPoints(user.uid);
            // Update combined activities
            _updateCombinedActivities();
          } else {
            userActivities = [];
            isLoading = false;
            _updateCombinedActivities();
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Error getting activities: $error');
          isLoading = false;
          
          // Show error message if context is available
          if (context != null) {
            ScaffoldMessenger.of(context!).showSnackBar(
              SnackBar(content: Text('Error fetching activity data: $error'))
            );
          }
          notifyListeners();
        }
      );
    } catch (e) {
      debugPrint('Error in _listenForActivities: $e');
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Calculate total points
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
      
      userPoints = totalUserPoints;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating total points: $e');
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch records from Firebase
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
      // Get all records
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
  
  // Update combined activities list
  void _updateCombinedActivities() {
    List<dynamic> activityData = [];
    int calculatedPoints = 0; // Reset points counter
    
    // Add regular activities and sum points
    for (var activity in userActivities) {
      activityData.add(activity);
      calculatedPoints += activity.pointsAdded;
    }
    
    // Add all record types and sum points
    userRecords.forEach((type, records) {
      for (var record in records) {
        final activity = record.toActivity();
        activityData.add(activity);
        calculatedPoints += activity.pointsAdded;
      }
    });
    
    // Sort by timestamp, newest first
    activityData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Convert to view-specific data
    List<ActivityDisplayData> combinedDisplayData = activityData.map((item) => 
      ActivityDisplayData(
        activity: item.activity,
        timestamp: item.timestamp,
        pointsAdded: item.pointsAdded
      )
    ).toList();
    
    allActivities = combinedDisplayData; // Store all activities
    
    // Decide whether to show all or just the first 5
    combinedActivities = showAllActivities || combinedDisplayData.length <= 5 
        ? combinedDisplayData 
        : combinedDisplayData.sublist(0, 5);
    
    userPoints = calculatedPoints;
    
    // Store the data in the shared service for other ViewModels to access
    _recordsService.setRecordsData(userRecords);
    
    notifyListeners();
  }
  
  // Toggle showing all activities
  void toggleShowAllActivities() {
    showAllActivities = !showAllActivities;
    
    // Update displayed activities based on the toggle state
    combinedActivities = showAllActivities || allActivities.length <= 5 
        ? allActivities 
        : allActivities.sublist(0, 5);
    notifyListeners();
  }
  
  // Get a random motivational prompt
  String _getRandomPrompt() {
    int index = _random.nextInt(ProgressMeterData.motivationalPrompts.length);
    return ProgressMeterData.motivationalPrompts[index] != currentPrompt 
        ? ProgressMeterData.motivationalPrompts[index]
        : _getRandomPrompt(); // Try again if same as current
  }
  
  // Change the prompt
  void refreshPrompt() {
    currentPrompt = _getRandomPrompt();
    notifyListeners();
  }
  
  // Helper method to format datetime
  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // Check if user has enough points
  bool hasEnoughPoints() {
    // For testing we're returning true, in production you'd use:
    // return userPoints >= totalPoints;
    return true;
  }
  
  // Check if any record type is loading
  bool isAnyLoading() {
    return isLoading || isLoadingRecords.values.any((loading) => loading);
  }
  
  // Navigate to RecapReport1
  void navigateToRecap1(BuildContext context) {
    if (hasEnoughPoints()) {
      // Make sure data is stored in the service
      _recordsService.setRecordsData(userRecords);
      
      // Navigate without passing data
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecapReport1()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient progress meter!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
