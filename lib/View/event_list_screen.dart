import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seek_here/ViewModel/progress_meter_viewmodel.dart';
import '../Model/location.dart';
import '../ViewModel/event_list_viewmodel.dart';
import 'event_detail_screen.dart';
import 'package:seek_here/Model/progress_meter_model.dart';

class EventListScreen extends StatelessWidget {
  final Location location;

  const EventListScreen({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    
    return ChangeNotifierProvider(
      create: (_) => EventListViewModel(),
      child: Consumer<EventListViewModel>(
        builder: (context, viewModel, child) {
          final ProgressMeterViewModel progressMeterViewModel = ProgressMeterViewModel();
          // Check if we need to navigate back due to error
          if (viewModel.shouldNavigateBack) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.navigationHandled();
              Navigator.pop(context);
            });
          }
          
          // Show error snackbar if needed
          if (viewModel.shouldShowErrorSnackbar && viewModel.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.error!),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
              viewModel.errorSnackbarShown();
            });
          }
          
          // Fetch events when the screen is first loaded
          if (viewModel.events.isEmpty && !viewModel.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.fetchEvents(location);
            });
          }

          if (!viewModel.isLoading && viewModel.events.isNotEmpty && !viewModel.hasShownRecommenderToast) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Set flag before showing toast to prevent multiple executions
              viewModel.markRecommenderToastAsShown();
                    progressMeterViewModel.showProgressUpdateToast(context, 'recommender');
                    RecordEntry.insertTimestampToCollection("recommender");
            });
          }

          return Scaffold(
            body: Stack(
              children: [
                // Background waves
                Positioned.fill(
                  child: CustomPaint(
                    painter: WavePainter(),
                  ),
                ),
                
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Custom App Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                // Reset the recommender toast flag when navigating back
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.black54),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Nearby Events',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => viewModel.fetchEvents(location),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh, color: Colors.black54),
                              ),
                            )
                          ],
                        ),
                      ),

                      // Subtitle text (as in image 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Any event can be clicked to view the details of the event.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),

                      // Display current location
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location.address ?? 'Current Location',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Main content area - Loading, Error, or Event List
                      Expanded(
                        child: _buildMainContent(context, viewModel, dateFormat, location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Extract the content building to a separate method for clarity
  Widget _buildMainContent(BuildContext context, EventListViewModel viewModel, DateFormat dateFormat, Location location) {
    // First render state: Show loading indicator when actively loading
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding events near you...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    
    // Second render state: Show error with retry button (if not navigating back)
    if (viewModel.error != null && !viewModel.shouldNavigateBack) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${viewModel.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.fetchEvents(location),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    // Third render state: Events are empty but we're not loading (no events found)
    if (viewModel.events.isEmpty) {
      // This is a real empty state AFTER loading is complete
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No events found nearby.\nTry a different location or refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }
    
    // Fourth render state: Show events list when available
    return RefreshIndicator(
      onRefresh: () => viewModel.fetchEvents(location),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: viewModel.events.length,
        itemBuilder: (context, index) {
          final event = viewModel.events[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      event: event,
                    ),
                  ),
                ).then((_) {
                  // Update the favorites status
                  viewModel.updateEventFavoriteStatus(event.id);
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event image or placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                              ? Image.network(
                                  event.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.event, size: 40),
                                    );
                                  },
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.event, size: 40),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.organizer,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dateFormat.format(event.startDate),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (event.isFavorite)
                          const Icon(Icons.favorite, color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.address ?? 'No address available',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event.fee <= 0 ? 'Free' : 'RM ${event.fee.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: event.fee <= 0 ? Colors.green : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(
                                  event: event,
                                ),
                              ),
                            ).then((_) {
                              // Update the favorites status
                              viewModel.updateEventFavoriteStatus(event.id);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF8E97FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(70, 32),
                          ),
                          child: const Text('VIEW'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left wave
    Paint topWavePaint = Paint()
      ..color = Color(0xFF8E97FD).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    Path topWavePath = Path();
    topWavePath.moveTo(0, 0);
    topWavePath.lineTo(0, size.height * 0.35);
    topWavePath.quadraticBezierTo(
      size.width * 0.5, 
      size.height * 0.45, 
      size.width * 0.7, 
      size.height * 0.25
    );
    topWavePath.quadraticBezierTo(
      size.width * 0.85, 
      size.height * 0.1, 
      size.width, 
      size.height * 0.15
    );
    topWavePath.lineTo(size.width, 0);
    topWavePath.close();
    
    canvas.drawPath(topWavePath, topWavePaint);

    // Bottom-right wave
    Paint bottomWavePaint = Paint()
      ..color = Color(0xFF8E97FD).withValues(alpha: 0.4) 
      ..style = PaintingStyle.fill;

    Path bottomWavePath = Path();
    bottomWavePath.moveTo(size.width, size.height);
    bottomWavePath.lineTo(size.width * 0.7, size.height);
    bottomWavePath.quadraticBezierTo(
      size.width * 0.5, 
      size.height * 0.95, 
      size.width * 0.3, 
      size.height * 0.85
    );
    bottomWavePath.quadraticBezierTo(
      size.width * 0.1, 
      size.height * 0.75, 
      size.width * 0.15, 
      size.height * 0.65
    );
    bottomWavePath.lineTo(size.width, size.height * 0.65);
    bottomWavePath.close();
    
    canvas.drawPath(bottomWavePath, bottomWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}