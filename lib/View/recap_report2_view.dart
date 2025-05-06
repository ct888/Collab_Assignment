import 'package:flutter/material.dart';
import 'package:seek_here/View/utils/pie_chart_painter.dart';
import 'package:provider/provider.dart';
import 'package:seek_here/ViewModel/recap_report2_viewmodel.dart';

class RecapReport2 extends StatefulWidget {
  const RecapReport2({super.key});

  @override
  State<RecapReport2> createState() => _RecapReport2State();
}

class _RecapReport2State extends State<RecapReport2> {
  late RecapReport2ViewModel viewModel;
  
  @override
  void initState() {
    super.initState();
    viewModel = RecapReport2ViewModel();
    viewModel.initialize();
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
              image: AssetImage("assets/bg/RecapReport2Bg.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Empty space at top to match RecapReport1 (replacing X button)
                    SizedBox(height: screenSize.height * 0.03),
                    
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
                    Consumer<RecapReport2ViewModel>(
                      builder: (context, viewModel, child) {
                        if (viewModel.isLoading) {
                          return SizedBox(
                            height: screenSize.height * 0.6,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        } else if (viewModel.interactionData.isEmpty) {
                          return SizedBox(
                            height: screenSize.height * 0.6,
                            child: Center(
                              child: Text(
                                "No interaction data available.",
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
                          return Column(
                            children: [
                              // Description with dynamic total points
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.015),
                                child: Text(
                                  'For the last ${viewModel.totalDays} days, you have gathered ${viewModel.totalPoints} progress meter points:',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF525252),
                                    fontSize: 16,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.02),
                              
                              // Pie Chart
                              SizedBox(
                                width: screenSize.width * 0.5,
                                height: screenSize.width * 0.5,
                                child: CustomPaint(
                                  painter: PieChartPainter(
                                    data: viewModel.interactionData,
                                    getPercentage: (item) => (item as InteractionDisplayData).percentage,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.02),
                              
                              // Legend title
                              const Text(
                                'List of interactions made:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              SizedBox(height: screenSize.height * 0.01),
                              
                              // Interaction items
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: viewModel.interactionData.asMap().entries.map((entry) => 
                                  _buildInteractionItem(
                                    context,
                                    '${entry.value.name} (${entry.value.points} points) - ${(entry.value.percentage * 100).toStringAsFixed(1)}%', 
                                    PieChartPainter.chartColors[entry.key % PieChartPainter.chartColors.length]
                                  )
                                ).toList(),
                              ),
                              
                              // Add spacer to push the congratulations text and buttons to the bottom
                              SizedBox(height: screenSize.height * 0.15),
                            ],
                          );
                        }
                      },
                    ),
                    
                    // Congratulations text
                    const Text(
                      'Congratulations!\nYou have achieved the goal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF525252),
                        fontSize: 24,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    
                    SizedBox(height: screenSize.height * 0.025),
                    
                    // Back and End buttons in a row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button - left aligned
                        ElevatedButton(
                          onPressed: () {
                            // Navigate back to previous page (RecapReport1)
                            Navigator.of(context).pop();
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
                              Icon(Icons.arrow_back, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'ADLaM Display',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // End button - right aligned
                        ElevatedButton(
                          onPressed: () {
                            // Navigate back to ProgressMeter (popping both RecapReport2 and RecapReport1)
                            Navigator.of(context).popUntil((route) => route.isFirst);
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
                                'End',
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
                      ],
                    ),
                    
                    SizedBox(height: screenSize.height * 0.025),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionItem(BuildContext context, String text, Color color) {
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