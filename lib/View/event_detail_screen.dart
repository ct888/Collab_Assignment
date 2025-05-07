// views/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Model/event.dart';
import '../ViewModel/event_detail_viewmodel.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventDetailViewModel(
        event: widget.event,
      ),
      child: Consumer<EventDetailViewModel>(
        builder: (context, viewModel, child) {
          final event = viewModel.currentEvent;
          
          // Set up map markers
          _markers = {
            Marker(
              markerId: const MarkerId('event_location'),
              position: LatLng(
                event.location.latitude,
                event.location.longitude,
              ),
              infoWindow: InfoWindow(
                title: event.title,
                snippet: event.location.address,
              ),
            ),
          };

          return Scaffold(
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildEventDetails(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildEventDetails(
    BuildContext context, 
    EventDetailViewModel viewModel
  ) {
    final event = viewModel.currentEvent;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    final startDate = dateFormat.format(event.startDate);
    final startTime = timeFormat.format(event.startDate);
    final endTime = timeFormat.format(event.endDate);
    
    // Define theme colors for consistent styling
    final Color accentColor = Color(0xFF8880FF); // Purple accent color from design
    final Color dividerColor = Colors.grey.shade300;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200.0,
          backgroundColor: Color(0xFF8E97FD),
          pinned: true,
          leading: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            background: event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Color(0xFF8E97FD),
                        child: const Center(
                          child: Icon(
                            Icons.event,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Color(0xFF8E97FD),
                    child: const Center(
                      child: Icon(
                        Icons.event,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  event.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: event.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  viewModel.toggleFavorite();
                },
              ),
            ),
          ],
        ),

        // Event Details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Organizer
                _buildMetaInfoRow(
                  icon: Icons.person,
                  iconColor: Colors.blue,
                  content: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Organised By ',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                        ),
                        TextSpan(
                          text: event.organizer,
                          style: TextStyle(color: accentColor, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date and Time
                _buildMetaInfoRow(
                  icon: Icons.calendar_today,
                  iconColor: Colors.orange,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startDate,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$startTime - $endTime',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                _buildMetaInfoRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  content: Text(
                    event.location.address ?? 'No address available',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                _buildMetaInfoRow(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  content: Text(
                    event.fee <= 0
                        ? 'Free Entry'
                        : '\$${event.fee.toStringAsFixed(2)} per person',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Divider(color: dividerColor, thickness: 1),
                
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      _buildTabItem("EVENT DETAILS", 0, accentColor),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // About This Event
                _buildSectionTitle('About this event'),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 20),
                
                // Divider
                Divider(color: dividerColor, thickness: 1),
                const SizedBox(height: 16),
                
                // Requirements
                if (event.requirements.isNotEmpty) ...[
                  _buildSectionTitle('Requirements'),
                  const SizedBox(height: 12),
                  ..._buildRequirementsList(event.requirements, accentColor),
                  const SizedBox(height: 20),
                  
                  // Divider before location
                  Divider(color: dividerColor, thickness: 1),
                  const SizedBox(height: 16),
                ],

                // Location Title
                _buildSectionTitle('Location'),
                const SizedBox(height: 12),
                
                // Map
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          event.location.latitude,
                          event.location.longitude,
                        ),
                        zoom: 14.0,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Know more button (if URL is available)
                if (event.webUrl != null && event.webUrl!.isNotEmpty)
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () => _launchUrl(event.webUrl!),
                      child: const Text(
                        'KNOW MORE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaInfoRow({
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  List<Widget> _buildRequirementsList(List<String> requirements, Color bulletColor) {
    return requirements.map((requirement) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(fontSize: 16, color: bulletColor, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                requirement,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTabItem(String title, int index, Color activeColor) {
    final bool isActive = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: activeColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    // First ensure the URL has proper formatting
    String processedUrl = url;
    
    // If URL doesn't start with http:// or https://, add https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      processedUrl = 'https://$url';
    }
    
    try {
      final Uri uri = Uri.parse(processedUrl);
      
      // Try to launch in external browser
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch $processedUrl');
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url. Invalid URL format or app not found.')),
      );
    }
  }
}