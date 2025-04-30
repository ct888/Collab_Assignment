import 'package:flutter/material.dart';
import 'dart:math' as math;

// Add Interaction data model
class InteractionData {
  final String name;
  final int points;
  final Color color;
  final double percentage;

  InteractionData({
    required this.name,
    required this.points,
    required this.color,
    double? percentage,
  }) : percentage = percentage ?? 0.0;
  
  // Factory method to create InteractionData list with auto-calculated percentages
  static List<InteractionData> createWithPercentages(List<InteractionData> interactions) {
    // Calculate total points
    int total = interactions.fold(0, (sum, interaction) => sum + interaction.points);
    
    // Create new list with calculated percentages
    return interactions.map((interaction) => InteractionData(
      name: interaction.name,
      points: interaction.points,
      color: interaction.color,
      percentage: total > 0 ? interaction.points / total : 0.0,
    )).toList();
  }
}

class RecapReport2 extends StatelessWidget {
  const RecapReport2({super.key});
  
  // Predefined colors for interaction types
  static const List<Color> interactionColors = [
    Color(0xFFE9E9E9), // Light gray
    Color(0xFF4361EE), // Blue
    Color(0xFF7209B7), // Purple
    Color(0xFFF72585), // Pink
  ];
  
  // Generate interaction data with auto-calculated percentages
  List<InteractionData> _generateInteractionData() {
    // Create initial data
    final initialInteractions = [
      InteractionData(name: 'Record Mood', points: 133, color: Colors.transparent),
      InteractionData(name: 'Write Diary', points: 144, color: Colors.transparent),
      InteractionData(name: 'Request Recommender', points: 125, color: Colors.transparent),
      InteractionData(name: 'Write Diary', points: 150, color: Colors.transparent),
    ];
    
    // Assign colors from the predefined list
    for (int i = 0; i < initialInteractions.length; i++) {
      final colorIndex = i % interactionColors.length;
      initialInteractions[i] = InteractionData(
        name: initialInteractions[i].name,
        points: initialInteractions[i].points,
        color: interactionColors[colorIndex],
      );
    }
    
    // Calculate and assign percentages
    var result = InteractionData.createWithPercentages(initialInteractions);

    // Sort by points in descending order
    result.sort((a, b) => b.points.compareTo(a.points));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for relative calculations
    final Size screenSize = MediaQuery.of(context).size;
    final List<InteractionData> interactionData = _generateInteractionData();
    final int totalPoints = interactionData.fold(0, (sum, interaction) => sum + interaction.points);
    
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
                
                // Description with dynamic total points
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.015),
                  child: Text(
                    'For the last 20 days, you have gathered $totalPoints progress meter points:',
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
                
                // Pie Chart - removed percentage labels
                SizedBox(
                  width: screenSize.width * 0.5,
                  height: screenSize.width * 0.5, // Using width to maintain aspect ratio
                  child: CustomPaint(
                    painter: InteractionPieChartPainter(interactionData),
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.02),
                
                // Legend title - centered like in RecapReport1
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
                
                // Interaction items - dynamically generated with percentages
                Center(
                  child: SizedBox(
                    height: screenSize.height * 0.15,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: interactionData.map((interaction) => 
                          _buildInteractionItem(
                            '${interaction.name} (${interaction.points} points) - ${(interaction.percentage * 100).toStringAsFixed(2)}%', 
                            interaction.color
                          )
                        ).toList(),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
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

  Widget _buildInteractionItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Updated QuadrantPieChartPainter to use actual percentages
class InteractionPieChartPainter extends CustomPainter {
  final List<InteractionData> interactionData;

  InteractionPieChartPainter(this.interactionData);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Starting position for the first segment (top of the circle)
    var startAngle = -math.pi / 2;
    
    for (int i = 0; i < interactionData.length; i++) {
      final paint = Paint()
        ..color = interactionData[i].color
        ..style = PaintingStyle.fill;
      
      // Calculate the angle based on the percentage
      final sweepAngle = interactionData[i].percentage * 2 * math.pi;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Update the start angle for the next segment
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}