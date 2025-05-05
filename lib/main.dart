import 'package:flutter/material.dart';
import 'package:seek_here/View/progress_meter_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Program start here
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProgressMeter(),
  ));
}

