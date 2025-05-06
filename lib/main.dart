import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/View/login.dart';
import 'package:seek_here/View/progress_meter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seek_here/viewmodels/moodViewModel.dart';
import 'package:seek_here/viewmodels/musicViewModel.dart';
import 'package:seek_here/viewmodels/videoViewModel.dart';
import 'firebase_options.dart';
// import 'package:seek_here/View/recap_report1.dart';
// import 'package:seek_here/View/recap_report2.dart'; // Corrected import path

// Program start here
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <--- Ensure Flutter binding is initialized

  await Firebase.initializeApp( // <--- Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // runApp(MyApp());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MoodViewModel()),
        ChangeNotifierProvider(create: (context) => VideoViewModel()),
        ChangeNotifierProvider(create: (context) => MusicViewModel()),
      ],
      child: MyApp(),
    ),
  );


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seek Here',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B88F9)),
        useMaterial3: true,
        fontFamily: GoogleFonts.aDLaMDisplay().fontFamily,
      ),
      // You can choose your start page here
      home: const LogIn(), // Start with login page
      // Alternatively, you could directly start with mood dashboard for testing
      // home: const MoodDashboardPage(),
      // home: const ProgressMeter(),
    );
  }
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

