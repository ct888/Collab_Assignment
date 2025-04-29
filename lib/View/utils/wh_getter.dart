import 'package:flutter/widgets.dart';

class WHGetter {
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double sx(BuildContext context, double val) {
    double w = MediaQuery.of(context).size.width;
    const double designWidth = 414; 
    return val * (w / designWidth);
  }

  static double sy(BuildContext context, double val) {
    double y = MediaQuery.of(context).size.height;
    const double designHeight = 896; 
    return val * (y / designHeight);
  }
}
