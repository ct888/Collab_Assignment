import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wh_getter.dart';
import 'package:seek_here/Model/appimages.dart';
import 'customcolors.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: WHGetter.sx(context, 10),
      children: [
        Text(
          "Seek",
          style: GoogleFonts.aDLaMDisplay(
            fontSize: 16,
            height: 1.0,
            letterSpacing: 16 * 0.24,
            color: CustomColors.grayDark,
          ),
        ),
        Image.asset(
          AppImages.logo,
          width: 30,
          height: 30,
        ),
        Text(
          "Here",
          style: GoogleFonts.aDLaMDisplay(
            fontSize: 16,
            height: 1.0,
            letterSpacing: 16 * 0.24,
            color: CustomColors.grayDark,
          ),
        ),
      ],
    );
  }
}
