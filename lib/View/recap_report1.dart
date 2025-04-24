import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:seekhere_proj/View/recap_report2.dart'; // Import RecapReport2

class RecapReport1 extends StatelessWidget {
  const RecapReport1({super.key});

  @override
  Widget build(BuildContext context) {
    // Get device screen size for relative calculations
    final Size screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9BDEAC), // Light green
              Color(0xFF76E5CE), // Teal
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center everything
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
                
                // Description
                const Text(
                  'For the last 20 days, you have recorded 40 times of your mood:',
                  textAlign: TextAlign.center, // Center-aligned
                  style: TextStyle(
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
                    painter: MoodPieChartPainter(),
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
                
                // Mood legend items - centered and with relative height
                SizedBox(
                  height: screenSize.height * 0.22,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMoodItem(context, 'Happy (15 times) - 37.75%', const Color(0xFFE9E9E9)),
                        _buildMoodItem(context, 'Sleepy (5 times) - 12.25%', const Color(0xFF0CA2A8)),
                        _buildMoodItem(context, 'Sad (5 times) - 12.25%', const Color(0xFF0B64AD)),
                        _buildMoodItem(context, 'Angry (5 times) - 12.25%', const Color(0xFF7209B7)),
                        _buildMoodItem(context, 'Relax (5 times) - 12.25%', const Color(0xFFB5179E)),
                        _buildMoodItem(context, 'Boring (5 times) - 12.25%', const Color(0xFFF72585)),
                      ],
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
        mainAxisSize: MainAxisSize.min, // Make row only as wide as needed
        children: [
          Container(
            width: screenWidth * 0.04,
            height: screenWidth * 0.04,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MoodPieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Define colors for each slice - matching the screenshot exactly
    final colors = [
      const Color(0xFFF5F5F5), // Happy - light grey/white
      const Color(0xFF22B7BF), // Sleepy - teal
      const Color(0xFF2969B0), // Sad - blue
      const Color(0xFF6900B9), // Angry - purple
      const Color(0xFFC01E9F), // Relax - magenta
      const Color(0xFFFF3E90), // Boring - pink
    ];
    
    // Define angles for each slice (in radians)
    final percentages = [0.3775, 0.1225, 0.1225, 0.1225, 0.1225, 0.1225];
    
    var startAngle = -math.pi / 2; // Start from top (minus 90 degrees)
    
    for (int i = 0; i < percentages.length; i++) {
      final sweepAngle = 2 * math.pi * percentages[i];
      
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill
        ..strokeWidth = 0; // No stroke
      
      // Draw arc with no gap between slices
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Optional: Draw a small white circle in the center for aesthetics
    final centerPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, 0, centerPaint); // Zero radius means no circle
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}