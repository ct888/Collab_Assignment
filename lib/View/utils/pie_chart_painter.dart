import 'package:flutter/material.dart';
import 'dart:math' as math;

class PieChartPainter extends CustomPainter {
  final List<dynamic> data;
  final double Function(dynamic item) getPercentage;
  
  // Combined color palette for all chart types
  static const List<Color> chartColors = [
    Color(0xFFF5F5F5), // Light grey/white
    Color(0xFF22B7BF), // Teal
    Color(0xFFC01E9F), // Magenta
    Color(0xFF2969B0), // Blue
    Color(0xFF6900B9), // Purple
    Color(0xFFFF3E90), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
  ];
  
  PieChartPainter({
    required this.data, 
    required this.getPercentage,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    var startAngle = -math.pi / 2; // Start from top (minus 90 degrees)
    
    for (int i = 0; i < data.length; i++) {
      final paint = Paint()
        ..color = chartColors[i]
        ..style = PaintingStyle.fill;
      
      final sweepAngle = getPercentage(data[i]) * 2 * math.pi;
      
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
  // This method is called to determine if the painter should repaint
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      // Compare data lists
      if (data.length != oldDelegate.data.length) {
        return true;
      }
      
      // Check if data content changed
      for (int i = 0; i < data.length; i++) {
        if (getPercentage(data[i]) != oldDelegate.getPercentage(oldDelegate.data[i])) {
          return true;
        }
      }
      
      return false;
    }
    return true;
  }
}
