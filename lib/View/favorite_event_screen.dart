// views/favorite_events_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../ViewModel/utils/favorite_event_viewmodel.dart';
import '../Model/event.dart';
import 'event_detail_screen.dart';

class FavoriteEventsScreen extends StatelessWidget {
  final String userId;

  const FavoriteEventsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoriteEventsViewModel(userId: userId),
      child: Consumer<FavoriteEventsViewModel>(
        builder: (context, viewModel, child) {
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
                              'Favorite Events',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => viewModel.refreshFavorites(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Subtitle text
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Swipe left to remove an event from favorites or tap to view details.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),

                      // Content area
                      Expanded(
                        child: _buildContent(context, viewModel),
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

  Widget _buildContent(BuildContext context, FavoriteEventsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
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
              onPressed: () => viewModel.refreshFavorites(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (viewModel.favoriteEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorite events yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find events and tap the heart icon to save them',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshFavorites(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: viewModel.favoriteEvents.length,
        itemBuilder: (context, index) {
          final event = viewModel.favoriteEvents[index];
          return _buildFavoriteEventCard(context, event, viewModel);
        },
      ),
    );
  }

  Widget _buildFavoriteEventCard(
    BuildContext context, 
    Event event, 
    FavoriteEventsViewModel viewModel
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    final startDateStr = dateFormat.format(event.startDate);

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Remove Event'),
              content: const Text(
                'Are you sure you want to remove this event from your favorites?'
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        viewModel.removeFromFavorites(event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.title} removed from favorites'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // This is a placeholder for the undo action
                viewModel.refreshFavorites();
              },
            ),
          ),
        );
      },
      child: Card(
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
              // Refresh favorites when returning from details
              viewModel.refreshFavorites();
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
                                  startDateStr,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        viewModel.removeFromFavorites(event.id);
                      },
                    ),
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
                        ).then((_) {
                          viewModel.refreshFavorites();
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
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left wave
    Paint topWavePaint = Paint()
      ..color = Color(0xFF8E97FD).withOpacity(0.4) // Matching color from event list screen
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