import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/ViewModel/boa_vm.dart';
import 'package:seek_here/View/widget/input_widget.dart';
import 'package:seek_here/View/widget/logo_widget.dart';
import 'package:seek_here/View/utils/ui_animation.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/widget/button_widget.dart';
import 'package:seek_here/View/utils/wh_getter.dart';

class BoaView extends StatefulWidget {
  const BoaView({super.key});

  @override
  State<BoaView> createState() => _BoaViewState();
}

class _BoaViewState extends State<BoaView> {
  final TextEditingController _preferenceController = TextEditingController();

  void _submit(){
    final preference = _preferenceController.text.trim();
    
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BoaVM(preference: preference,))
      );
    
  }

  @override
  Widget build(BuildContext context) {
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
                    // Logo
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: LogoWidget(),
                    ),
                    // Title
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
                    // Description
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
                    // Button
                    Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: PulsingWrapper(
                        child: IconButtonWidget(
                          icon: Icons.book_rounded,
                          size: w / 2,
                          iconColor: CustomColors.black,
                          backgroundColor: CustomColors.pink,
                          onPressed: _submit, 
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 50, bottom: 100),
                      child: InputText(
                        label: "What's happening now?",
                        width: w * 0.9,
                        height: 70,
                        controller: _preferenceController,
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
