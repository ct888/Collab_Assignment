import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/View/music_home_page.dart';
import 'package:seek_here/View/utils/customcolors.dart';
import 'package:seek_here/View/video_home_page.dart';
import 'event_recommender_screen.dart';
import 'package:seek_here/View/widget/logo_widget.dart';

class RecommenderScreen extends StatelessWidget {
  final String userId;

  const RecommenderScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background wave in top-left
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF8E97FD).withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Background wave in bottom-right
          Positioned(
            right: -80,
            bottom: 100,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF8E97FD).withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Centered Logo
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LogoWidget(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Recommend header
                    Text(
                      'Recommend',
                      style: GoogleFonts.aDLaMDisplay(
                        fontSize: 28,
                      ),
                    ),

                    Text(
                      'We wish you have a good day',
                      style: GoogleFonts.aDLaMDisplay(fontSize: 16, color: CustomColors.grayMid),
                    ),

                    const SizedBox(height: 30),

                    // Activity Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EventRecommenderScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E97FD),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // Left content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Activity',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'NEARBY EVENT',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      'START',
                                      style: GoogleFonts.aDLaMDisplay(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8E97FD),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right image
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: Image.asset(
                                'assets/recommender_module1.png',
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Relaxation Music Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusicPlayerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8FE3CF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // Left content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Relaxation',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 24,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'MUSIC',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      'START',
                                      style: GoogleFonts.aDLaMDisplay(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right image
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Image.asset(
                                'assets/recommender_module2.png',
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.headphones,
                                        size: 40,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Relaxation Video Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC288),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // Left content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Relaxation',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 24,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'VIDEO',
                                    style: GoogleFonts.aDLaMDisplay(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      'START',
                                      style: GoogleFonts.aDLaMDisplay(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFFC288),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right image
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: Image.asset(
                                'assets/recommender_module3.png',
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.tv,
                                        size: 40,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Add bottom padding to ensure the last card isn't cut off by navigation
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
