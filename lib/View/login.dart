import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/View/mainscreen.dart';
import 'package:seek_here/View/utils/button_widget.dart';
import 'package:seek_here/View/utils/logo_widget.dart';
import 'package:seek_here/View/utils/input_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/View/utils/customcolors.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful!', style: GoogleFonts.aDLaMDisplay()),
          backgroundColor: Colors.green,
        ),
      );

      final userId = FirebaseAuth.instance.currentUser!.uid;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(userId: user.uid)),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else {
        message = 'Login Failed: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.aDLaMDisplay()),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen Width & Height
    double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);

    // Text Input controller

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
                        InputText(
                          label: "Email",
                          width: w * 0.9,
                          height: 70,
                          controller: _emailController,
                        ),
                        // === Seperator ===
                        SizedBox(height: 10),
                        // Password Input
                        InputText(
                          label: "Password",
                          width: w * 0.9,
                          height: 70,
                          isSensitiveInput: true,
                          controller: _passwordController,
                        ),
                      ],
                    ),
                  ),

                  // Login Button
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: TextButtonWidget(
                      label: "Log In",
                      borderRadius: 38,
                      onPressed: () => _isLoading ? null : _loginUser(),
                      backgroundColor: CustomColors.blue,
                      width: w * 0.9,
                      height: 60,
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
