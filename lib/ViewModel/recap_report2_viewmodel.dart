import 'package:flutter/material.dart';
import 'package:seek_here/Model/progress_meter_model.dart';

// View-specific data class to avoid direct Model access from View
class InteractionDisplayData {
  final String name;
  final int points;
  final double percentage;

  InteractionDisplayData({
    required this.name,
    required this.points,
    required this.percentage,
  });
}

class RecapReport2ViewModel extends ChangeNotifier {
  bool isLoading = true;
  List<InteractionDisplayData> _interactionDisplayData = [];
  int totalPoints = 0;
  int totalDays = 1; // Default value
  
  final UserRecords _records = UserRecords();
  
  // Expose display data for the view
  List<InteractionDisplayData> get interactionData => _interactionDisplayData;
  
  // Initialize view model
  void initialize() {
    Map<String, List<dynamic>>? preloadedRecords = _records.getRecordsData();
    
    if (preloadedRecords != null && preloadedRecords.isNotEmpty) {
      processInteractionData(preloadedRecords);
    } else {
      // No data available, set empty state
      _interactionDisplayData = [];
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Process interaction records to generate statistics
  void processInteractionData(Map<String, List<dynamic>> records) {
    Map<String, int> pointsByActivity = {};
    DateTime? latestDate;
    DateTime? oldestDate;
    
    // Count activity type occurrences and calculate date range
    records.forEach((type, recordList) {
      // Skip if list is empty
      if (recordList.isEmpty) return;
      
      // Create activity name based on record type and get points per activity
      String activityName = '';
      int pointsPerActivity = RecordEntry.getPointsForType(type);
      
      activityName = UserActivity.standardizeActivityName(type);
      
      // Skip if no valid activity name
      if (activityName.isEmpty) return;
      
      // Count points for this activity type using the specific point value
      int activityPoints = recordList.length * pointsPerActivity;
      pointsByActivity[activityName] = (pointsByActivity[activityName] ?? 0) + activityPoints;
      
      // Track date range
      for (var record in recordList) {
        DateTime timestamp = record.timestamp;
        
        if (latestDate == null || timestamp.isAfter(latestDate!)) {
          latestDate = timestamp;
        }
        if (oldestDate == null || timestamp.isBefore(oldestDate!)) {
          oldestDate = timestamp;
        }
      }
    });
    
    // Calculate date range in days
    if (latestDate != null && oldestDate != null) {
      totalDays = latestDate!.difference(oldestDate!).inDays + 1;
      if (totalDays < 1) totalDays = 1;
    }
    
    // Convert to internal InteractionData objects
    List<InteractionData> interactions = pointsByActivity.entries.map(
      (entry) => InteractionData(name: entry.key, points: entry.value)
    ).toList();
    
    // Calculate percentages and sort
    final processedInteractions = InteractionData.createWithPercentages(interactions);
    processedInteractions.sort((a, b) => b.points.compareTo(a.points));
    
    // Convert Model data to View-specific display data
    _interactionDisplayData = processedInteractions.map((interaction) => InteractionDisplayData(
      name: interaction.name,
      points: interaction.points,
      percentage: interaction.percentage
    )).toList();
    
    // Calculate total points
    int calculatedTotalPoints = interactions.fold(0, (sum, item) => sum + item.points);
    
    totalPoints = calculatedTotalPoints;
    isLoading = false;
    notifyListeners();
  }
}
