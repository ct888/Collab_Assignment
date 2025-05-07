import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/Model/appimages.dart';
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

  bool _inCurrentPage(int index) => currentIndex == index;

  @override
  Widget build(BuildContext context) {
    double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);

    final List<Map<String, String>> navItems = [
      {'icon': AppImages.bookOpened, 'label': 'BOA'},
      {'icon': AppImages.compass, 'label': 'Recommend'},
      {'icon': AppImages.happyFace, 'label': 'Mood'},
      {'icon': AppImages.bookAndPen, 'label': 'Diary'},
      {'icon': AppImages.user, 'label': 'Account'},
    ];

    return SafeArea(
      child: Container(
        height: 70,
        width: w,
        decoration: BoxDecoration(color: CustomColors.grayLight),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (index) {
            return GestureDetector(
              onTap: () => onTap(index),
              child: SizedBox(
                width: _inCurrentPage(index) ? w*0.2 + 10 :  w*0.2 - 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration:
                          _inCurrentPage(index)
                              ? BoxDecoration(
                                color: CustomColors.blue.withAlpha(255),
                                borderRadius: BorderRadius.circular(8),
                              )
                              : null,
                      child: SvgPicture.asset(
                        navItems[index]['icon']!,
                        width: 40,
                        height: 30,
                        colorFilter: ColorFilter.mode(
                          _inCurrentPage(index)
                              ? CustomColors.white
                              : CustomColors.grayDark,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      navItems[index]['label']!,
                      style: GoogleFonts.aDLaMDisplay(
                        color:
                            _inCurrentPage(index)
                                ? CustomColors.blue
                                : CustomColors.grayDark,
                        fontSize: _inCurrentPage(index) ? 12 : 10, // Reduced
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
