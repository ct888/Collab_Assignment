import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/View/progress_meter.dart';
// import 'package:seek_here/View/recap_report1.dart';
// import 'package:seek_here/View/recap_report2.dart'; // Corrected import path

// Program start here
void main() {
  // runApp(MyApp());
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProgressMeter(),
  ));
}

// Paint UI to screen
class App extends StatelessWidget {
  const App({super.key});

  // Rebuild UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Hello World'),
        ),
      
        body:ListView.builder(
            itemBuilder: (_, index) {
              Color currentColor = randomColor();
              return Container(
                color: currentColor,
                width: 500,
                height: 200,
                child: Text(
                  randomColor().toString(),
                  style: TextStyle(
                    fontFamily: GoogleFonts.aBeeZee().fontFamily,
                    fontWeight: FontWeight.bold,
                    color: currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white
                  )
                )
                
              );
            },
        )
      )
    );
  }
  
  Color randomColor() {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withAlpha(255);
  }
}

