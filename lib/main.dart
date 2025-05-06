import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/View/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seek_here/viewmodels/moodViewModel.dart';
import 'package:seek_here/viewmodels/musicViewModel.dart';
import 'package:seek_here/viewmodels/videoViewModel.dart';
import 'firebase_options.dart';

// Program start here
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <--- Ensure Flutter binding is initialized

  await Firebase.initializeApp(
    // <--- Initialize Firebase
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
