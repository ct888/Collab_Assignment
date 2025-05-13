// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/View/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seek_here/ViewModel/moodViewModel.dart';
import 'package:seek_here/ViewModel/musicViewModel.dart';
import 'package:seek_here/ViewModel/videoViewModel.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
   // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock Screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Dotenv
  await dotenv.load(fileName: '.env');

  runApp(

    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MoodViewModel()),
        ChangeNotifierProvider(create: (context) => VideoViewModel()),
        ChangeNotifierProvider(create: (context) => MusicViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LogIn(),
      ),
    ),
  );
}