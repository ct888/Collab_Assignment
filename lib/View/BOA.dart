import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/View/utils/input_widget.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
import 'package:seek_here/View/utils/ui_animation.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/button_widget.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/BaseLayout.dart';

class BOA extends StatefulWidget {
  const BOA({super.key});

  @override
  State<BOA> createState() => _BOAState();
}

class _BOAState extends State<BOA> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: h,
          child: Stack(
            children: [
              // Vector Bg
              Positioned(
                top: 60,
                left: -2,
                child: SvgPicture.asset(AppImages.bgCloud),
              ),

              // Content
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: LogoWidget(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: Text(
                        "Book of Answer",
                        style: GoogleFonts.aDLaMDisplay(
                          fontSize: 28,
                          color: CustomColors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: 300,
                        child: Text(
                          "Think a question in your mind, and get your answer with one click...",
                          style: GoogleFonts.aDLaMDisplay(
                            fontSize: 16,
                            color: CustomColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: PulsingWrapper(
                        child: IconButtonWidget(
                          icon: Icons.book_rounded,
                          size: w / 2,
                          iconColor: CustomColors.black,
                          backgroundColor: CustomColors.pink,
                          onPressed: () {
                            // TODO
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 50, bottom: 100),
                      child: TextInput(
                        label: "What's happening now?",
                        width: w * 0.9,
                        height: 70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
