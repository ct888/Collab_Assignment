import 'package:flutter/material.dart';
import 'package:seek_here/View/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Program start here
void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // <--- Ensure Flutter binding is initialized

  await Firebase.initializeApp( // <--- Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // runApp(MyApp());
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LogIn(),
  ));
}


