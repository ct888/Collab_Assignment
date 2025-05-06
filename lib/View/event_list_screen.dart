// views/event_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Model/location.dart';
import '../ViewModel/utils/event_list_viewmodel.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatelessWidget {
  final String userId;
  final Location location;

  const EventListScreen({
    Key? key,
    required this.userId,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    return ChangeNotifierProvider(
      create: (_) => EventListViewModel(userId: userId),
      child: Consumer<EventListViewModel>(
        builder: (context, viewModel, child) {
          // Fetch events when the screen is first loaded
          if (viewModel.events.isEmpty && !viewModel.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.fetchEvents(location);
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
                              onTap: () => Navigator.pop(context),
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
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => viewModel.fetchEvents(location),
                            ),
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
                                color: Colors.black.withOpacity(0.05),
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

                      // Loading indicator or error message
                      if (viewModel.isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (viewModel.error != null)
                        Expanded(
                          child: Center(
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
                          ),
                        )
                      else if (viewModel.events.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No events found nearby. Try a different location or refresh.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        // Show event list with original layout but styled cards
                        Expanded(
                          child: RefreshIndicator(
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
                                            userId: userId,
                                            event: event,
                                          ),
                                        ),
                                      ).then((_) {
                                        // Instead of refreshing all events, just update the favorites status if needed
                                        final index = viewModel.events.indexWhere((e) => e.id == event.id);
                                        if (index != -1) {
                                          viewModel.events[index].isFavorite = event.isFavorite;
                                        }
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
                                                        userId: userId,
                                                        event: event,
                                                      ),
                                                    ),
                                                  );
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
                          ),
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
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left wave
    Paint topWavePaint = Paint()
      ..color = Color(0xFF8E97FD).withOpacity(0.4) // Matching color from 2nd image
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
      ..color = Color(0xFF8E97FD).withOpacity(0.4) 
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
