import 'package:flutter/material.dart';
import 'package:seek_here/Model/progress_meter_model.dart';
import 'package:seek_here/Service/user_records_service.dart';
import 'package:seek_here/View/recap_report2_view.dart';

// View-specific data class to avoid direct Model access from View
class MoodDisplayData {
  final String name;
  final int count;
  final double percentage;

  MoodDisplayData({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

class RecapReport1ViewModel extends ChangeNotifier {
  bool isLoading = true;
  List<MoodDisplayData> _moodDisplayData = [];
  int totalDays = 20; // Default value
  final UserRecordsService _recordsService = UserRecordsService();
  
  // Expose display data for the view
  List<MoodDisplayData> get moodData => _moodDisplayData;
  
  // Process mood records to generate statistics
  void processMoodRecords(List<dynamic> records) {
    Map<String, int> moodCounts = {};
    DateTime? latestDate;
    DateTime? oldestDate;
    
    for (var record in records) {
      // Extract mood and timestamp from record
      String mood = record.data['mood'] ?? 'Unknown';
      DateTime timestamp = record.timestamp;
      
      // Update date range tracking
      if (latestDate == null || timestamp.isAfter(latestDate)) {
        latestDate = timestamp;
      }
      if (oldestDate == null || timestamp.isBefore(oldestDate)) {
        oldestDate = timestamp;
      }
      
      // Count the mood occurrences
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }
    
    // Calculate date range in days
    if (latestDate != null && oldestDate != null) {
      totalDays = latestDate.difference(oldestDate).inDays + 1;
      if (totalDays < 1) totalDays = 1;
    }
    
    // Convert to internal MoodData objects
    List<MoodData> moods = moodCounts.entries.map(
      (entry) => MoodData(name: entry.key, count: entry.value)
    ).toList();
    
    // Calculate percentages and sort
    final processedMoods = MoodData.createWithPercentages(moods);
    processedMoods.sort((a, b) => b.count.compareTo(a.count));
    
    // Convert Model data to View-specific display data
    _moodDisplayData = processedMoods.map((mood) => MoodDisplayData(
      name: mood.name,
      count: mood.count,
      percentage: mood.percentage
    )).toList();
    
    isLoading = false;
    notifyListeners();
  }
  
  // Initialize view model
  void initialize() {
    Map<String, List<dynamic>>? preloadedRecords = _recordsService.getRecordsData();
    
    if (preloadedRecords != null && preloadedRecords.containsKey('mood')) {
      processMoodRecords(preloadedRecords['mood']!);
    } else {
      // No data available, set empty state
      _moodDisplayData = [];
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Navigate to next screen
  void navigateToRecap2(BuildContext context) {
    // Navigate without passing data, RecapReport2ViewModel will get data from service
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecapReport2()),
    );
  }
  
  // Get total mood count
  int getTotalMoodCount() {
    return _moodDisplayData.fold(0, (sum, mood) => sum + mood.count);
  }
}