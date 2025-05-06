import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/View/utils/customcolors.dart';

class InputText extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool isSensitiveInput;
  final double? width;
  final double? height;

  const InputText({
    super.key,
    required this.label,
    this.controller,
    this.isSensitiveInput = false,
    this.width,
    this.height,
  });
  
  final double _fontSize = 16.0;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 100,
      height: height ?? 30,
      child: TextField(
        controller: controller,
        obscureText: isSensitiveInput,
        style: GoogleFonts.aDLaMDisplay(
          fontSize: _fontSize,
          letterSpacing: _fontSize * 0.05, 
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: (height ?? 30) * 0.25,
            horizontal: 16,
          ),
          labelText: label,
          labelStyle: GoogleFonts.aDLaMDisplay(
            fontSize: _fontSize,
            letterSpacing: _fontSize * 0.05,
            color: CustomColors.grayMid,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: CustomColors.grayLight
        ),

      ),
    );
  }
} 