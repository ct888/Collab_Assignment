import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/View/utils/button_widget.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
import 'package:seek_here/View/utils/input_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/utils/customcolors.dart';

import 'BOA.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LogIn(), // Set your login screen here
    );
  }
}

class LogIn extends StatelessWidget {
  const LogIn({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen Width & Height

    double w = WHGetter.width(context);
    double h = WHGetter.height(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // White background
            Container(width: w, height: h, color: CustomColors.white),

            // Vector background image
            Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset(AppImages.bgLogin),
            ),

            // Main Content
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Padding(
                    padding: EdgeInsets.only(top: WHGetter.sy(context, 50)),
                    child: LogoWidget(),
                  ),

                  // Welcome Back Text
                  Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Text(
                      "Welcome Back\u0021",
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 28,
                        height: 1.35,
                        color: CustomColors.grayDark,
                      ),
                    ),
                  ),

                  // LogIn Title
                  Padding(
                    padding: EdgeInsets.only(top: 90),
                    child: Text(
                      "LOG IN WITH EMAIL".toUpperCase(),
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 14,
                        height: 1.08,
                        letterSpacing: 14 * 0.05,
                      ),
                    ),
                  ),

                  // Email and Password Input
                  Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Email Input
                        TextInput(
                          label: "Email",
                          width: 374, //TODO: tO DYnamic
                          height: 70, // TODO: to dynamic
                        ),
                        // === Seperator ===
                        SizedBox(height: 10),
                        // Password Input
                        TextInput(
                          label: "Password",
                          width: 374, // TODO: same
                          height: 70, // TODO same
                          isSensitiveInput: true,
                        ),
                      ],
                    ),
                  ),

                  // Login Button
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ButtonWidget(
                      label: "Log In",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Boa()),
                        );
                      },
                      color: CustomColors.blue,
                      width: WHGetter.sx(context, 374),
                      height: WHGetter.sy(context, 60),
                    ),
                  ),

                  // Forgot Password
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      "Forgot Password\u003F",
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 14,
                        letterSpacing: 14 * 0.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
