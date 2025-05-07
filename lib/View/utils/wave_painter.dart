import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint topWavePaint = Paint()
      ..color = const Color.fromARGB(255, 39, 53, 255).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    Path topWavePath = Path();
    topWavePath.moveTo(0, 0);
    topWavePath.lineTo(0, size.height * 0.35);
    topWavePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45,
      size.width * 0.7,
      size.height * 0.25,
    );
    topWavePath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.1,
      size.width,
      size.height * 0.15,
    );
    topWavePath.lineTo(size.width, 0);
    topWavePath.close();

    canvas.drawPath(topWavePath, topWavePaint);

    Paint bottomWavePaint = Paint()
      ..color = const Color.fromARGB(255, 39, 53, 255).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    Path bottomWavePath = Path();
    bottomWavePath.moveTo(size.width, size.height);
    bottomWavePath.lineTo(size.width * 0.7, size.height);
    bottomWavePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.95,
      size.width * 0.3,
      size.height * 0.85,
    );
    bottomWavePath.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.75,
      size.width * 0.15,
      size.height * 0.65,
    );
    bottomWavePath.lineTo(size.width, size.height * 0.65);
    bottomWavePath.close();

    canvas.drawPath(bottomWavePath, bottomWavePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
