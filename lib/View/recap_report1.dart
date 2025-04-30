import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:seekhere_proj/View/recap_report2.dart'; // Import RecapReport2

// Mood data model
class MoodData {
  final String name;
  final int count;
  final Color color;
  final double percentage;

  MoodData({
    required this.name,
    required this.count,
    required this.color,
    double? percentage,
  }) : percentage = percentage ?? 0.0;
  
  // Factory method to create MoodData list with auto-calculated percentages
  static List<MoodData> createWithPercentages(List<MoodData> moods) {
    // Calculate total count
    int total = moods.fold(0, (sum, mood) => sum + mood.count);
    
    // Create new list with calculated percentages
    return moods.map((mood) => MoodData(
      name: mood.name,
      count: mood.count,
      color: mood.color,
      percentage: total > 0 ? mood.count / total : 0.0,
    )).toList();
  }
}

class RecapReport1 extends StatelessWidget {
  const RecapReport1({super.key});
  
  // Predefined colors for mood types
  static const List<Color> moodColors = [
    Color(0xFFF5F5F5), // Happy - light grey/white
    Color(0xFF22B7BF), // Sleepy - teal
    Color(0xFF2969B0), // Sad - blue
    Color(0xFF6900B9), // Angry - purple
    Color(0xFFC01E9F), // Relax - magenta
    Color(0xFFFF3E90), // Boring - pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
  ];

  // Generate sample mood data with auto-calculated percentages
  List<MoodData> _generateMoodData() {
    // Create initial data (counts only)
    final initialMoods = [
      MoodData(name: 'Happy', count: 22, color: Colors.transparent),
      MoodData(name: 'Sleepy', count: 13, color: Colors.transparent),
      MoodData(name: 'Sad', count: 25, color: Colors.transparent),
      MoodData(name: 'Angry', count: 5, color: Colors.transparent),
      MoodData(name: 'Relax', count: 5, color: Colors.transparent),
      MoodData(name: 'Boring', count: 5, color: Colors.transparent),
      // You can add or remove mood types as needed
    ];
    
    // Assign colors from the predefined list
    for (int i = 0; i < initialMoods.length; i++) {
      final colorIndex = i % moodColors.length; // Cycle through colors if more moods than colors
      initialMoods[i] = MoodData(
        name: initialMoods[i].name,
        count: initialMoods[i].count,
        color: moodColors[colorIndex],
      );
    }
    
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
                  height: screenSize.width * 0.5, // Using width for aspect ratio
                  child: CustomPaint(
                    painter: MoodPieChartPainter(moodData),
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
                        children: moodData.map((mood) => _buildMoodItem(
                          context, 
                          '${mood.name} (${mood.count} times) - ${(mood.percentage * 100).toStringAsFixed(2)}%', 
                          mood.color
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

class MoodPieChartPainter extends CustomPainter {
  final List<MoodData> moodData;
  
  MoodPieChartPainter(this.moodData);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    var startAngle = -math.pi / 2; // Start from top (minus 90 degrees)
    
    // Draw all slices with the correction applied
    for (int i = 0; i < moodData.length; i++) {
      final paint = Paint()
        ..color = moodData[i].color
        ..style = PaintingStyle.fill;
      
      final sweepAngle = moodData[i].percentage * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is MoodPieChartPainter) {
      return oldDelegate.moodData != moodData;
    }
    return true;
  }
}