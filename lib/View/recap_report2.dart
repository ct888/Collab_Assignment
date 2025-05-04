import 'package:flutter/material.dart';
import 'package:seek_here/View/utils/pie_chart_painter.dart';
import 'package:seek_here/View/progress_meter.dart'; // Import the progress_meter file

// Interaction data model
class InteractionData {
  final String name;
  final int points;
  double percentage = 0.0;

  InteractionData({
    required this.name,
    required this.points,
  });
  
  static List<InteractionData> createWithPercentages(List<InteractionData> interactions) {
    int total = interactions.fold(0, (sum, interaction) => sum + interaction.points);

    return interactions.map((interaction) {
      double percentage = total > 0 ? interaction.points / total : 0.0;
      return InteractionData(
        name: interaction.name,
        points: interaction.points,
      )..percentage = percentage;
    }).toList();
  }
}

class RecapReport2 extends StatefulWidget {
  // Add preloaded records parameter
  final Map<String, List<dynamic>>? preloadedRecords;
  
  const RecapReport2({super.key, this.preloadedRecords});

  @override
  State<RecapReport2> createState() => _RecapReport2State();
}

class _RecapReport2State extends State<RecapReport2> {
  bool isLoading = true;
  List<InteractionData> interactionData = [];
  int totalPoints = 0;
  int totalDays = 20; // Default value
  
  @override
  void initState() {
    super.initState();
    
    // Process preloaded data
    if (widget.preloadedRecords != null && widget.preloadedRecords!.isNotEmpty) {
      _processInteractionData(widget.preloadedRecords!);
    } else {
      // No data available, set empty state
      setState(() {
        interactionData = [];
        isLoading = false;
      });
    }
  }

  // Process the preloaded records to generate interaction statistics
  void _processInteractionData(Map<String, List<dynamic>> records) {
    Map<String, int> pointsByActivity = {};
    DateTime? latestDate;
    DateTime? oldestDate;
    
    // Count activity type occurrences and calculate date range
    records.forEach((type, recordList) {
      // Skip if list is empty
      if (recordList.isEmpty) return;
      
      // Create activity name based on record type and get points per activity from RecordEntry
      String activityName = '';
      int pointsPerActivity = RecordEntry.getPointsForType(type); // Get points from RecordEntry class
      
      switch (type) {
        case 'mood':
          activityName = 'Record Mood';
          break;
        case 'quote':
          activityName = 'Request Quote';
          break;
        case 'diary':
          activityName = 'Write Diary';
          break;
        case 'recommender':
          activityName = 'Request Recommender';
          break;
      }
      
      // Skip if no valid activity name
      if (activityName.isEmpty) return;
      
      // Count points for this activity type using the specific point value from RecordEntry
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
    
    // Convert to InteractionData objects
    List<InteractionData> interactions = pointsByActivity.entries.map(
      (entry) => InteractionData(name: entry.key, points: entry.value)
    ).toList();
    
    // Calculate percentages and sort
    final processedInteractions = InteractionData.createWithPercentages(interactions);
    processedInteractions.sort((a, b) => b.points.compareTo(a.points));
    
    // Calculate total points
    int calculatedTotalPoints = interactions.fold(0, (sum, item) => sum + item.points);
    
    setState(() {
      interactionData = processedInteractions;
      totalPoints = calculatedTotalPoints;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for relative calculations
    final Size screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg/RecapReport2Bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Empty space at top to match RecapReport1 (replacing X button)
                SizedBox(height: screenSize.height * 0.03),
                
                // Title
                const Text(
                  'Recap Report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3F414E),
                    fontSize: 30,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.012),
                
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (interactionData.isEmpty)
                  // No data available
                  Expanded(
                    child: Center(
                      child: Text(
                        "No interaction data available.",
                        style: TextStyle(
                          color: const Color(0xFF525252),
                          fontSize: screenSize.width * 0.04,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        // Description with dynamic total points
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.015),
                          child: Text(
                            'For the last $totalDays days, you have gathered $totalPoints progress meter points:',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF525252),
                              fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenSize.height * 0.02),
                        
                        // Pie Chart
                        SizedBox(
                          width: screenSize.width * 0.5,
                          height: screenSize.width * 0.5,
                          child: CustomPaint(
                            painter: PieChartPainter(
                              data: interactionData,
                              getPercentage: (item) => (item as InteractionData).percentage,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenSize.height * 0.02),
                        
                        // Legend title
                        const Text(
                          'List of interactions made:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        SizedBox(height: screenSize.height * 0.01),
                        
                        // Interaction items
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: interactionData.asMap().entries.map((entry) => 
                                _buildInteractionItem(
                                  context,
                                  '${entry.value.name} (${entry.value.points} points) - ${(entry.value.percentage * 100).toStringAsFixed(1)}%', 
                                  PieChartPainter.chartColors[entry.key % PieChartPainter.chartColors.length]
                                )
                              ).toList(),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                      ],
                    ),
                  ),
                
                // Congratulations text
                const Text(
                  'Congratulations!\nYou have achieved the goal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF525252),
                    fontSize: 24,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.025),
                
                // Back and End buttons in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button - left aligned
                    ElevatedButton(
                      onPressed: () {
                        // Navigate back to previous page (RecapReport1)
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBB5F5),
                        foregroundColor: const Color(0xFF3F414E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.075,
                          vertical: screenSize.height * 0.015,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'ADLaM Display',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // End button - right aligned
                    ElevatedButton(
                      onPressed: () {
                        // Navigate back to ProgressMeter (popping both RecapReport2 and RecapReport1)
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBB5F5),
                        foregroundColor: const Color(0xFF3F414E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.075,
                          vertical: screenSize.height * 0.015,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'End',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'ADLaM Display',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenSize.height * 0.025),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionItem(BuildContext context, String text, Color color) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.004),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(width: screenWidth * 0.05),
          Container(
            width: screenWidth * 0.04,
            height: screenWidth * 0.04,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}