import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/View/Boa.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';

class HomeNavbarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HomeNavbarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Color _iconColor(int index) =>
      currentIndex == index ? CustomColors.blue : CustomColors.grayMid;

  @override
  Widget build(BuildContext context) {
    double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);

    final List<Map<String, String>> navItems = [
      {'icon': AppImages.bookOpened, 'label': 'BOA'},
      {'icon': AppImages.happyFace, 'label': 'Mood'},
      {'icon': AppImages.compass, 'label': 'Recommender'},
      {'icon': AppImages.bookAndPen, 'label': 'Diary'},
      {'icon': AppImages.user, 'label': 'Account'},
    ];

    return Container(
      height: 60,
      width: w,
      decoration: BoxDecoration(color: CustomColors.grayLight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = currentIndex == index;
          final color = isSelected ? CustomColors.blue : CustomColors.grayMid;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  navItems[index]['icon']!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                SizedBox(height: 4),
                Text(
                  navItems[index]['label']!,
                  style: GoogleFonts.aDLaMDisplay(
                    color: color,
                    fontSize: 12,
                  )
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
