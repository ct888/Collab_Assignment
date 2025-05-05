import 'package:flutter/material.dart';
import 'package:seek_here/View/recap_report2_view.dart';
import 'package:seek_here/View/utils/pie_chart_painter.dart';
import 'package:seek_here/ViewModel/recap_report1_viewmodel.dart';
import 'package:provider/provider.dart';

class RecapReport1 extends StatefulWidget {
  final Map<String, List<dynamic>>? preloadedRecords;
  
  const RecapReport1({super.key, this.preloadedRecords});

  @override
  State<RecapReport1> createState() => _RecapReport1State();
}

class _RecapReport1State extends State<RecapReport1> {
  late RecapReport1ViewModel viewModel;
  
  @override
  void initState() {
    super.initState();
    viewModel = RecapReport1ViewModel();
    viewModel.initialize(widget.preloadedRecords);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bg/RecapReport1Bg.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: screenSize.height * 0.006),
                      child: CircleAvatar(
                        radius: screenSize.width * 0.05,
                        backgroundColor: const Color(0xDDC4C4C4),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.black54, size: screenSize.width * 0.05),
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenSize.height * 0.01),
                  
                  // Title
                  const Text(
                    'Recap Report',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3F414E),
                      fontSize: 30,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  SizedBox(height: screenSize.height * 0.012),
                  
                  // Content - Using Consumer to listen to view model changes
                  Consumer<RecapReport1ViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.isLoading) {
                        return const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (viewModel.moodData.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              "No mood data available.",
                              style: TextStyle(
                                color: const Color(0xFF525252),
                                fontSize: screenSize.width * 0.04,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                'For the last ${viewModel.totalDays} days, you have recorded ${viewModel.getTotalMoodCount()} times of your mood:',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 18,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.02),
                              
                              // Pie Chart
                              SizedBox(
                                width: screenSize.width * 0.5,
                                height: screenSize.width * 0.5,
                                child: CustomPaint(
                                  painter: PieChartPainter(
                                    data: viewModel.moodData,
                                    getPercentage: (item) => (item as MoodDisplayData).percentage,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.02),
                              
                              const Text(
                                'List of moods recorded:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 1.1,
                                  letterSpacing: -0.40,
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.01),
                              
                              // Dynamic mood legend items - Removed Expanded widget to let content use available space
                              SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: viewModel.moodData.asMap().entries.map((entry) => _buildMoodItem(
                                    context, 
                                    '${entry.value.name} (${entry.value.count} times) - ${(entry.value.percentage * 100).toStringAsFixed(1)}%', 
                                    PieChartPainter.chartColors[entry.key % PieChartPainter.chartColors.length]
                                  )).toList(),
                                ),
                              ),
                              
                              // Removed the Spacer to allow content to use more space
                              SizedBox(height: screenSize.height * 0.02),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  
                  // Next button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RecapReport2(
                            preloadedRecords: widget.preloadedRecords,
                          )),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBB5F5),
                        foregroundColor: const Color(0xFF3F414E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.075,
                          vertical: screenSize.height * 0.015,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'ADLaM Display',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenSize.height * 0.025),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodItem(BuildContext context, String text, Color color) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.004),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(width: screenWidth * 0.05),
          Container(
            width: screenWidth * 0.04,
            height: screenWidth * 0.04,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}