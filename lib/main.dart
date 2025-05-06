import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seek_here/View/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Program start here
void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // <--- Ensure Flutter binding is initialized

  // Lock Screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp( // <--- Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LogIn(),
  ));
}


