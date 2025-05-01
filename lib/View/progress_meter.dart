import 'package:flutter/material.dart';
import 'package:seek_here/View/recap_report1.dart';
import 'dart:math';

int points = 500;
const int totalPoints = 500;

// List of motivational prompts
final List<String> motivationalPrompts = [
  'Keep going! You can do it!',
  'You\'re making great progress!',
  'Every step counts, keep moving forward!',
  'Believe in yourself, you\'re amazing!',
  'Small steps lead to big changes!',
  'Your journey matters, stay focused!',
  'You\'re stronger than you think!',
  'Progress over perfection!',
  'Today is a new opportunity!',
  'One day at a time, you got this!',
  'Stay positive, stay motivated!',
  'You are capable of amazing things!',
  'Keep pushing, you\'re almost there!',
  'Success is a journey, not a destination!',
  'Every effort counts, keep it up!',
  'You are on the right track!',
  'Your hard work will pay off!',
  'Stay committed to your goals!',
  'You are making a difference!',
  'Keep striving for greatness!'
];

class ProgressMeter extends StatefulWidget {
  const ProgressMeter({super.key});

  @override
  State<ProgressMeter> createState() => _ProgressMeterState();
}

class _ProgressMeterState extends State<ProgressMeter> {
  // Initialize with empty string instead of using late
  String currentPrompt = '';
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    // Initialize with a random prompt
    currentPrompt = _getRandomPrompt();
  }
  
  // Get a random prompt from the list
  String _getRandomPrompt() {
    do {
      int index = _random.nextInt(motivationalPrompts.length);
      // Check if the prompt is not already selected
      if (motivationalPrompts[index] != currentPrompt) {
        return motivationalPrompts[index];
      }
    } while (true);
  }
  
  // Change the prompt
  void _refreshPrompt() {
    setState(() {
      currentPrompt = _getRandomPrompt();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get device size for responsive design
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg/ProgressMeterBg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.01,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  
                  SizedBox(height: screenHeight * 0.02), // 2% of screen height
                  
                  _buildMotivationalCard(context),
                  
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  
                  _buildProgressCircle(context),
                  
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  
                  _buildActivitiesSection(context),
                  
                  SizedBox(height: screenHeight * 0.02), // 2% of screen height
                  
                  _buildViewRecapButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double iconSize = size.width * 0.1; // 10% of screen width
    
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFBBBDC6),
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            _buildAppTitle(context),
            const Spacer(),
          ],
        ),
        SizedBox(height: size.height * 0.02),
        const Center(
          child: Text(
            'Progress Meter',
            style: TextStyle(
              color: Color(0xFF3F414E),
              fontSize: 24,
              fontFamily: 'ADLaM Display',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppTitle(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double outerCircleSize = size.width * 0.075; // 7.5% of screen width
    // final double innerCircleSize = outerCircleSize * 0.4; // 40% of outer circle
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Seek',
          style: TextStyle(
            color: Color(0xFF3F414E),
            fontSize: 16,
            fontFamily: 'ADLaM Display',
            fontWeight: FontWeight.w400,
            letterSpacing: 3.84,
          ),
        ),
        SizedBox(width: size.width * 0.015),
        Image.asset(
          'assets/logo.png',
          width: outerCircleSize,
          height: outerCircleSize,
          fit: BoxFit.contain,
        ),
        SizedBox(width: size.width * 0.015),
        const Text(
          'Here',
          style: TextStyle(
            color: Color(0xFF3F414E),
            fontSize: 16,
            fontFamily: 'ADLaM Display',
            fontWeight: FontWeight.w400,
            letterSpacing: 3.84,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalCard(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double cardHeight = size.height * 0.12; // 12% of screen height
    final double refreshIconSize = size.width * 0.1; // 10% of screen width
    
    return Container(
      width: double.infinity,
      height: cardHeight,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF8E97FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Motivational Prompt',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  currentPrompt,
                  style: const TextStyle(
                    color: Color(0xFF464A55),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.55,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refreshPrompt,
            child: Container(
              width: refreshIconSize,
              height: refreshIconSize,
              decoration: const BoxDecoration(
                color: Color(0xFF3F414E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double circleSize = size.width * 0.4; // 40% of screen width
    final double strokeWidth = size.width * 0.04; // 4% of screen width
    
    return Center(
      child: SizedBox(
        width: circleSize,
        height: circleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: CircularProgressIndicator(
                value: points / totalPoints,
                backgroundColor: const Color(0xFFD0D2FF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
                strokeWidth: strokeWidth,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Goal icon added above the text
                Image.asset(
                  'assets/icon/Icon-Goal.png',
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                  color: const Color(0xFF8E97FD),
                ),
                SizedBox(height: size.height * 0.008),
                Text(
                  'Progress Meter Points',
                  style: TextStyle(
                    color: const Color(0xFF525252),
                    fontSize: size.width * 0.025, // 2.5% of screen width
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w400,
                    height: 1.60,
                    letterSpacing: 0.40,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                    '$points of $totalPoints',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF262626),
                    fontSize: size.width * 0.03, // 3% of screen width
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                    letterSpacing: -0.40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 5 most recent activities done:',
          style: TextStyle(
            color: const Color(0xFF525252),
            fontSize: size.width * 0.035, // 3.5% of screen width
            fontFamily: 'Lato',
            fontWeight: FontWeight.w500,
            height: 1.61,
            letterSpacing: -0.28,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.015
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Activity',
                        style: TextStyle(
                          color: const Color(0xFF525252),
                          fontSize: size.width * 0.025,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w700,
                          height: 1.60,
                          letterSpacing: 0.40,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Time',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF525252),
                          fontSize: size.width * 0.025,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w700,
                          height: 1.60,
                          letterSpacing: 0.40,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Points Added',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF525252),
                          fontSize: size.width * 0.025,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w700,
                          height: 1.60,
                          letterSpacing: 0.40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFC2C2C2)),
              _buildActivityRow(context, 'Wrote a diary', '01/04/2025 11:23:45', '+ 5'),
              const Divider(height: 1, color: Color(0xFFC2C2C2)),
              _buildActivityRow(context, 'Recorded mood', '30/03/2025 20:24:07', '+ 5'),
              const Divider(height: 1, color: Color(0xFFC2C2C2)),
              _buildActivityRow(context, 'Requested quote', '29/03/2025 09:23:45', '+ 5'),
              const Divider(height: 1, color: Color(0xFFC2C2C2)),
              _buildActivityRow(context, 'Requested recommender', '28/03/2025 19:53:45', '+ 5'),
              const Divider(height: 1, color: Color(0xFFC2C2C2)),
              _buildActivityRow(context, 'Recorded mood', '27/03/2025 22:24:07', '+ 5'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(BuildContext context, String activity, String time, String points) {
    final Size size = MediaQuery.of(context).size;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04, 
        vertical: size.height * 0.01
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              activity,
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.025,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                height: 1.60,
                letterSpacing: 0.40,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.025,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                height: 1.60,
                letterSpacing: 0.40,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              points,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.025,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                height: 1.60,
                letterSpacing: 0.40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewRecapButton(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool hasEnoughPoints = points >= totalPoints;
    
    return Center(
      child: ElevatedButton(
        onPressed: hasEnoughPoints 
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecapReport1()),
                );
              } 
            : () {
                // Show toast message for insufficient points
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient progress meter!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: hasEnoughPoints 
              ? const Color(0xFFBBB5F5)  // Original purple color
              : Colors.grey,             // Grey for disabled state
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(38),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08, 
            vertical: size.height * 0.015
          ),
        ),
        child: Text(
          'View Recap',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF3F414E),
            fontSize: size.width * 0.04, // 4% of screen width
            fontFamily: 'ADLaM Display',
            fontWeight: FontWeight.w400,
            height: 1.08,
            letterSpacing: 0.80,
          ),
        ),
      ),
    );
  }
}
