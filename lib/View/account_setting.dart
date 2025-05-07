import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/View/login.dart';
import 'package:seek_here/View/progress_meter_view.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
import 'package:seek_here/View/utils/wh_getter.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSetting();
}

class _AccountSetting extends State<AccountSetting> {
  final _auth = FirebaseAuth.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {

    final double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);
    String _email = _user?.email ?? 'User';

    return SafeArea(
      child: Stack(
        children: [
          // Vector Bg
          Positioned(
            bottom: -(h*0.6),
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

                // Profile
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: CustomColors.blue,
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // For square with rounded corners
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SvgPicture.asset(
                            AppImages.user,
                            fit: BoxFit.cover,
                          ), // your SVG path
                        ),
                      ),

                      // Name
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          _email,
                          style: GoogleFonts.aDLaMDisplay(fontSize: 24),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Divider(thickness: 1.5, color: CustomColors.grayDark),
                      ListTile(
                        title: Center(
                          child: Text(
                            "View Progress Meter",
                            style: GoogleFonts.aDLaMDisplay(fontSize: 24),
                          ),
                        ),

                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProgressMeter(),
                              ),
                            ),
                      ),
                      Divider(thickness: 1.5, color: CustomColors.grayDark),
                      ListTile(
                        title: Center(
                          child: Text(
                            "Logout",
                            style: GoogleFonts.aDLaMDisplay(
                              fontSize: 24,
                              color: Colors.red,
                            ),
                          ),
                        ),

                        onTap: () async {
                          await _auth.signOut();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Logout Successful',
                                style: GoogleFonts.aDLaMDisplay(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LogIn()),
                          );
                        },
                      ),
                      Divider(thickness: 1.5, color: CustomColors.grayDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
