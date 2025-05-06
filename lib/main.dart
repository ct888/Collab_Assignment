import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/View/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seek_here/ViewModel/moodViewModel.dart';
import 'package:seek_here/ViewModel/musicViewModel.dart';
import 'package:seek_here/ViewModel/videoViewModel.dart';
import 'firebase_options.dart';

// Program start here
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <--- Ensure Flutter binding is initialized

  // Lock Screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp( // <--- Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

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