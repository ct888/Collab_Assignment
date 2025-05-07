import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seek_here/Model/progress_meter_model.dart';
import 'package:seek_here/View/recap_report1_view.dart';
import 'package:seek_here/Service/user_records_service.dart';

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
  // Replace fixed static value with a getter that dynamically checks current user
  static int get totalPoints {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return currentUid == 'AiTF3BPPtjSzlJXgQH0zGVaQjRp2' ? 100 : 500;
  }
  
  // Create a static instance that can be accessed globally
  static final ProgressMeterViewModel _instance = ProgressMeterViewModel._internal();
  
  // Factory constructor to return the singleton instance
  factory ProgressMeterViewModel() {
    return _instance;
  }
  
  // Private constructor for singleton
  ProgressMeterViewModel._internal() {
    currentPrompt = _getRandomPrompt();
  }
  
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
  
  // Initialize data
  void initialize(BuildContext context) {
    this.context = context;
    _listenForActivities();
    _fetchAllRecordTypes();
  }
  
  // Dispose resources
  @override
  void dispose() {
    // Cancel subscriptions but don't dispose the ChangeNotifier
    _cleanupSubscriptions();
    // Don't call super.dispose() since this is a singleton
  }

  // New method for cleaning up subscriptions without disposing
  void _cleanupSubscriptions() {
    _activitiesSubscription?.cancel();
    _activitiesSubscription = null;
    
    recordSubscriptions.forEach((key, subscription) {
      subscription?.cancel();
      recordSubscriptions[key] = null;
    });
  }
  
  // New method for reinitializing when needed
  void reinitialize(BuildContext context) {
    // Clean up any existing subscriptions
    _cleanupSubscriptions();
    
    // Set the context and initialize again
    this.context = context;
    _listenForActivities();
    _fetchAllRecordTypes();
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
      
      // MODIFIED QUERY - Remove where() clause
      final activitiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('activities')
          .orderBy('timestamp', descending: true);
      
      // Use stream for real-time updates
      _activitiesSubscription = activitiesRef.snapshots().listen(
        (querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            // Filter by userId in code
            userActivities = querySnapshot.docs
                .where((doc) {
                  Map<String, dynamic> data = doc.data();
                  return data['userId'] == uid;
                })
                .map((doc) {
                  Map<String, dynamic> data = doc.data();
                  // Extract data from the document
                  String activity = data['activity'] ?? 'Unknown activity';
                  
                  // Handle timestamp that might be null
                  final timestamp = data['timestamp'];
                  final DateTime date = timestamp is Timestamp 
                      ? timestamp.toDate() 
                      : DateTime.now();
                  
                  int pointsAdded = (data['pointsAdded'] ?? 0);
                  
                  // Use the standardizer helper from the model with userId parameter
                  return UserActivity.createStandardized(
                    activity, 
                    date, 
                    pointsAdded
                  );
                })
                .toList();
            
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
      // MODIFIED QUERY - Remove where() clause
      final pointsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities');
      
      final pointsSnapshot = await pointsRef.get();
      
      // Sum up all points, filtering by userId
      int totalUserPoints = 0;
      for (var doc in pointsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        if (data['userId'] == userId) {  // Filter by userId in code
          totalUserPoints += (data['pointsAdded'] as num? ?? 0).toInt();
        }
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
      // Get all records - MODIFIED QUERY
      // Option 1: Get all records and filter in code
      final collectionRef = FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy(orderByField, descending: true);
      
      // Listen for data
      final subscription = collectionRef.snapshots().listen(
        (querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            // Filter by userId in code rather than in the query
            final data = querySnapshot.docs
                .where((doc) {
                  Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                  return docData['userId'] == uid;
                })
                .map((doc) => RecordEntry.fromFirestore(doc, recordType))
                .toList();
            updateState(data, false);
          } else {
            // Try user-specific collection if root collection is empty
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // For user-specific collection, also modify the query
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection(collectionName)
                  .orderBy(orderByField, descending: true)
                  .get()
                  .then((snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  // Filter by userId in code
                  final data = snapshot.docs
                      .where((doc) {
                        Map<String, dynamic> docData = doc.data();
                        return docData['userId'] == uid;
                      })
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
    return userPoints >= totalPoints;
    // return true;
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

  // Show toast message for progress meter updates
  void showProgressUpdateToast(BuildContext context, String activityType) {
    // Get points for this activity type
    int points = RecordEntry.getPointsForType(activityType);
    
    // Ensure we have a context
    this.context = context;
    
    // Check if adding these points will reach or exceed the target
    if (userPoints >= totalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Congratulations! You have reached the goal, you can now view the recap.'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress meter updated (+$points points)'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.lightGreen,
        ),
      );
    }
  }
}
