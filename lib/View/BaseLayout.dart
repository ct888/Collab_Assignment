import 'package:flutter/material.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/navbar_widget.dart';
import 'package:seek_here/View/utils/wh_getter.dart';

class Baselayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTap;

  const Baselayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);

    return Scaffold(
      backgroundColor: CustomColors.white,
      body: body,
      bottomNavigationBar: HomeNavbarWidget(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}
