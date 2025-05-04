import 'package:flutter/material.dart';
import 'package:seek_here/View/recap_report2.dart';
import 'package:seek_here/View/utils/pie_chart_painter.dart';

// Mood data model
class MoodData {
  final String name;
  final int count;
  double percentage = 0.0;

  MoodData({
    required this.name,
    required this.count
  });

  static List<MoodData> createWithPercentages(List<MoodData> moods) {
    int totalCount = moods.fold(0, (sum, mood) => sum + mood.count);

    return moods.map((mood) {
      double percentage = totalCount > 0 ? mood.count / totalCount : 0.0;
      return MoodData(
        name: mood.name,
        count: mood.count
      )..percentage = percentage;
    }).toList();
  }
}

class RecapReport1 extends StatefulWidget {
  final Map<String, List<dynamic>>? preloadedRecords;
  
  const RecapReport1({super.key, this.preloadedRecords});

  @override
  State<RecapReport1> createState() => _RecapReport1State();
}

class _RecapReport1State extends State<RecapReport1> {
  bool isLoading = true;
  List<MoodData> moodData = [];
  int totalDays = 20; // Default value
  
  @override
  void initState() {
    super.initState();
    
    // Process the preloaded mood records immediately
    if (widget.preloadedRecords != null && widget.preloadedRecords!.containsKey('mood')) {
      _processMoodRecords(widget.preloadedRecords!['mood']!);
    } else {
      // No data available, set empty state
      setState(() {
        moodData = [];
        isLoading = false;
      });
    }
  }

  // Process mood records from the preloaded data
  void _processMoodRecords(List<dynamic> records) {
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
    
    // Convert to MoodData objects
    List<MoodData> moods = moodCounts.entries.map(
      (entry) => MoodData(name: entry.key, count: entry.value)
    ).toList();
    
    // Calculate percentages and sort
    final processedMoods = MoodData.createWithPercentages(moods);
    processedMoods.sort((a, b) => b.count.compareTo(a.count));
    
    setState(() {
      moodData = processedMoods;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg/RecapReport1Bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: screenSize.height * 0.006),
                    child: CircleAvatar(
                      radius: screenSize.width * 0.05,
                      backgroundColor: const Color(0xDDC4C4C4),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.black54, size: screenSize.width * 0.05),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.01),
                
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
                else if (moodData.isEmpty)
                  // No mood data available
                  Expanded(
                    child: Center(
                      child: Text(
                        "No mood data available.",
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
                  // Data available, show pie chart and details
                  Expanded(
                    child: Column(
                      children: [
                        // Description with dynamic total
                        Text(
                          'For the last $totalDays days, you have recorded ${moodData.fold(0, (sum, mood) => sum + mood.count)} times of your mood:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF525252),
                            fontSize: 18,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            letterSpacing: 0.4,
                          ),
                        ),
                        
                        SizedBox(height: screenSize.height * 0.02),
                        
                        // Pie Chart
                        SizedBox(
                          width: screenSize.width * 0.5,
                          height: screenSize.width * 0.5,
                          child: CustomPaint(
                            painter: PieChartPainter(
                              data: moodData,
                              getPercentage: (item) => (item as MoodData).percentage,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenSize.height * 0.02),
                        
                        // Legend title
                        const Text(
                          'List of moods recorded:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                            letterSpacing: -0.40,
                          ),
                        ),
                        
                        SizedBox(height: screenSize.height * 0.01),
                        
                        // Dynamic mood legend items
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: moodData.asMap().entries.map((entry) => _buildMoodItem(
                                context, 
                                '${entry.value.name} (${entry.value.count} times) - ${(entry.value.percentage * 100).toStringAsFixed(1)}%', 
                                PieChartPainter.chartColors[entry.key % PieChartPainter.chartColors.length]
                              )).toList(),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                      ],
                    ),
                  ),
                
                // Next button
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RecapReport2(
                          // Pass the same preloaded records to RecapReport2
                          preloadedRecords: widget.preloadedRecords,
                        )),
                      );
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
                          'Next',
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
                ),
                
                SizedBox(height: screenSize.height * 0.025),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodItem(BuildContext context, String text, Color color) {
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