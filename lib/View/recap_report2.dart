import 'package:flutter/material.dart';
import 'dart:math' as math;

class RecapReport2 extends StatelessWidget {
  const RecapReport2({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size for relative calculations
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
              Color(0xFFFFF159), // Yellow
              Color(0xFFF8B830), // Orange
            ],
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
                
                // Description - centered like RecapReport1
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.015),
                  child: const Text(
                    'For the last 20 days, you have gathered 500 progress meter points:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                
                // Pie Chart with responsive size
                SizedBox(
                  width: screenSize.width * 0.5,
                  height: screenSize.width * 0.5, // Using width to maintain aspect ratio
                  child: CustomPaint(
                    painter: QuadrantPieChartPainter(),
                    child: Center(
                      child: Stack(
                        children: [
                          // Top-left percentage (pink)
                          Positioned(
                            left: screenSize.width * 0.13,
                            top: screenSize.width * 0.13,
                            child: const Text(
                              '25%',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Top-right percentage (white/gray)
                          Positioned(
                            right: screenSize.width * 0.13,
                            top: screenSize.width * 0.13,
                            child: const Text(
                              '25%',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Bottom-left percentage (purple)
                          Positioned(
                            left: screenSize.width * 0.13,
                            bottom: screenSize.width * 0.13,
                            child: const Text(
                              '25%',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Bottom-right percentage (blue)
                          Positioned(
                            right: screenSize.width * 0.13,
                            bottom: screenSize.width * 0.13,
                            child: const Text(
                              '25%',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                
                // Interaction items with flexible height
                Center(
                  child: SizedBox(
                    height: screenSize.height * 0.15,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildInteractionItem('Record Mood (40 times) - 125 points', const Color(0xFFE9E9E9)),
                          buildInteractionItem('Write Diary (40 times) - 125 points', const Color(0xFF4361EE)),
                          buildInteractionItem('Request Recommender (40 times) - 125 points', const Color(0xFF7209B7)),
                          buildInteractionItem('Write Diary (40 times) - 125 points', const Color(0xFFF72585)),
                        ],
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

  Widget buildInteractionItem(String text, Color color) {
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

// QuadrantPieChartPainter remains unchanged
class QuadrantPieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Define colors for each quadrant - matching the screenshot exactly
    final colors = [
      const Color(0xFFF72585), // Top-left - Pink
      const Color(0xFFEAEAEA), // Top-right - Light gray
      const Color(0xFF7209B7), // Bottom-left - Purple
      const Color(0xFF4361EE), // Bottom-right - Blue
    ];
    
    // Each quadrant is exactly 25% of the circle (90 degrees or π/2 radians)
    const angle = math.pi / 2;
    
    // Starting position for the first quadrant (top-left)
    var startAngle = -math.pi / 2;
    
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        angle,
        true,
        paint,
      );
      
      startAngle += angle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}