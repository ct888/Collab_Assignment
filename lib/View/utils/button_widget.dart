import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/wh_getter.dart';

class ButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color? color;

  const ButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 100,
      height: height ?? 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? CustomColors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.aDLaMDisplay(
              fontSize: 16,
              letterSpacing: 16 * 0.05,
              color: CustomColors.grayDark,
            ),
          ),
        ),
      ),
    );
  }
}
