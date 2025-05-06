import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/ViewModel/progress_meter_viewmodel.dart';

class ProgressMeter extends StatefulWidget {
  const ProgressMeter({super.key});

  @override
  State<ProgressMeter> createState() => _ProgressMeterState();
}

class _ProgressMeterState extends State<ProgressMeter> {
  late ProgressMeterViewModel viewModel;

  @override
  void initState() {
    super.initState();
    // Create and initialize the view model
    viewModel = ProgressMeterViewModel();
  }
  
  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the view model with context after widget is mounted
    viewModel.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    // Get device size for responsive design
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    // Provide the view model to the widget tree
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        body: Container(
          height: screenHeight,
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
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    _buildMotivationalCard(context),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    _buildProgressCircle(context),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    _buildActivitiesSection(context),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    _buildViewRecapButton(context),
                    
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
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
    final double refreshIconSize = size.width * 0.1; // 10% of screen width
    
    return Consumer<ProgressMeterViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.02,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF8E97FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      viewModel.currentPrompt,
                      style: TextStyle(
                        color: const Color(0xFF464A55),
                        fontSize: size.width * 0.03,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.55,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(width: size.width * 0.02),
              GestureDetector(
                onTap: () => viewModel.refreshPrompt(),
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
      },
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
              child: Consumer<ProgressMeterViewModel>(
                builder: (context, viewModel, child) {
                  return CircularProgressIndicator(
                    value: (viewModel.userPoints / viewModel.totalPoints).clamp(0.0, 1.0), // Ensure value is between 0 and 1
                    backgroundColor: const Color(0xFFD0D2FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E97FD)),
                    strokeWidth: strokeWidth,
                  );
                },
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
                Consumer<ProgressMeterViewModel>(
                  builder: (context, viewModel, child) {
                    return Text(
                      '${viewModel.userPoints} of ${viewModel.totalPoints}', // Use userPoints instead of points
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF262626),
                        fontSize: size.width * 0.03, // 3% of screen width
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                        letterSpacing: -0.40,
                      ),
                    );
                  },
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
    
    return Consumer<ProgressMeterViewModel>(
      builder: (context, viewModel, child) {
        bool isAnyLoading = viewModel.isAnyLoading();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent activities done: ',
              style: TextStyle(
                color: const Color(0xFF525252),
                fontSize: size.width * 0.035,
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
              child: isAnyLoading
                  ? _buildLoadingIndicator()
                  : viewModel.combinedActivities.isNotEmpty
                      ? _buildCombinedList(context)
                      : _buildNoActivitiesMessage(context),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildNoActivitiesMessage(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.03
      ),
      child: Center(
        child: Text(
          "You have not interacted with the system yet",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF525252),
            fontSize: size.width * 0.035,
            fontFamily: 'Lato',
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCombinedList(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Consumer<ProgressMeterViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // Header row
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
                      'Activity Type',
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
                      'Points',
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
            
            // Activity rows
            ...viewModel.combinedActivities.map((item) {
              final String formattedDate = viewModel.formatDateTime(item.timestamp);
              return Column(
                children: [
                  _buildActivityRow(
                    context, 
                    item.activity, 
                    formattedDate, 
                    '+ ${item.pointsAdded}'
                  ),
                  const Divider(height: 1, color: Color(0xFFC2C2C2)),
                ],
              );
            }).toList(),
            
            // Show More/Less button if there are more than 5 activities
            if (viewModel.allActivities.length > 5)
              Center(
                child: TextButton(
                  onPressed: () => viewModel.toggleShowAllActivities(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8E97FD),
                  ),
                  child: Text(
                    viewModel.showAllActivities ? 'Show Less' : 'Show More',
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
    
    return Consumer<ProgressMeterViewModel>(
      builder: (context, viewModel, child) {
        final bool hasEnoughPoints = viewModel.hasEnoughPoints();
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Center(
            child: ElevatedButton(
              onPressed: hasEnoughPoints 
                  ? () => viewModel.navigateToRecap1(context)
                  : () {
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
                    ? const Color(0xFFBBB5F5)
                    : Colors.grey,
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
                  fontSize: size.width * 0.04,
                  fontFamily: 'ADLaM Display',
                  fontWeight: FontWeight.w400,
                  height: 1.08,
                  letterSpacing: 0.80,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
