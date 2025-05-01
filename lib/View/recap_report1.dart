import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:seek_here/View/recap_report2.dart'; // Import RecapReport2
import 'package:seek_here/View/utils/pie_chart_painter.dart'; // Import shared painter

// Mood data model
class MoodData {
  final String name;
  final int count;
  double percentage = 0.0; // Default percentage

  MoodData({
    required this.name,
    required this.count
  });

  // Factory method to create MoodData with calculated percentages
  static List<MoodData> createWithPercentages(List<MoodData> moods) {
    // Calculate total count of all moods
    int totalCount = moods.fold(0, (sum, mood) => sum + mood.count);

    // Calculate percentage for each mood
    return moods.map((mood) {
      double percentage = totalCount > 0 ? mood.count / totalCount : 0.0;
      return MoodData(
        name: mood.name,
        count: mood.count
        )..percentage = percentage;
    }).toList();
  }
}

class RecapReport1 extends StatelessWidget {
  const RecapReport1({super.key});

  // Generate sample mood data with auto-calculated percentages
  List<MoodData> _generateMoodData() {
    // Create initial data (counts only)
    final initialMoods = [
      MoodData(name: 'Happy', count: 22),
      MoodData(name: 'Sleepy', count: 13),
      MoodData(name: 'Sad', count: 25),
      MoodData(name: 'Angry', count: 15),
      MoodData(name: 'Relax', count: 5),
      MoodData(name: 'Boring', count: 5),
      // You can add or remove mood types as needed
    ];
    
    // Calculate and assign percentages
    var result = MoodData.createWithPercentages(initialMoods);
    
    // Sort by count in descending order (highest frequency first)
    result.sort((a, b) => b.count.compareTo(a.count));
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Get device screen size for relative calculations
    final Size screenSize = MediaQuery.of(context).size;
    final List<MoodData> moodData = _generateMoodData();
    
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
                // Close button - Explicitly navigate to ProgressMeter
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
                        onPressed: () => Navigator.of(context).pop(), // Return to ProgressMeter
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
                
                // Description with dynamic total count
                Text(
                  'For the last 20 days, you have recorded ${moodData.fold(0, (sum, mood) => sum + mood.count)} times of your mood:',
                  textAlign: TextAlign.center, // Center-aligned
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
                
                // Pie Chart with responsive sizing
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
                
                // Legend title - now centered
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
                Center(
                  child: SizedBox(
                    height: screenSize.height * 0.22,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: moodData.asMap().entries.map((entry) => _buildMoodItem(
                          context, 
                          '${entry.value.name} (${entry.value.count} times) - ${(entry.value.percentage * 100).toStringAsFixed(2)}%', 
                          PieChartPainter.chartColors[entry.key % PieChartPainter.chartColors.length]
                        )).toList(),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Next button - Updated with relative sizing
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecapReport2()),
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
    // Get screen width for relative sizing
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.004),
      child: Row(
        mainAxisSize: MainAxisSize.max, // Take full width to align items
        children: [
          SizedBox(width: screenWidth * 0.05), // Left padding for all items
          Container(
            width: screenWidth * 0.04,
            height: screenWidth * 0.04,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: screenWidth * 0.02), // Consistent spacing
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