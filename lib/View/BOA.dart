import 'package:flutter/material.dart';
import 'utils/wh_getter.dart';

class BOA extends StatelessWidget {
  const BOA({super.key});

  @override
  Widget build(BuildContext context) {
   double w = WHGetter.width(context);
    double h = WHGetter.height(context);

    return Scaffold(
      appBar: AppBar(title: const Text('First Route')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            
          }, child: const Text('Go Back')),
      ),
    );
  }
}
