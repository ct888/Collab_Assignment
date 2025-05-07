// views/event_recommender_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
//import 'package:seek_here/Model/progress_meter_model.dart';
import 'package:seek_here/View/favorite_event_screen.dart';
import '../ViewModel/event_recommender_viewmodel.dart';
import '../Viewmodel/progress_meter_viewmodel.dart';
import 'event_list_screen.dart';
import '../Model/location.dart';

class EventRecommenderScreen extends StatefulWidget {

  const EventRecommenderScreen({Key? key})
    : super(key: key);

  @override
  _EventRecommenderScreenState createState() => _EventRecommenderScreenState();
}

class _EventRecommenderScreenState extends State<EventRecommenderScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
 // final ProgressMeterViewModel _progressMeterViewModel = ProgressMeterViewModel();
  //Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  EventRecommenderViewModel? _viewModel;
  Location? _lastLocation;

  @override
  void dispose() {
    _mapController?.dispose();
    _addressController.dispose();
    _placeNameController.dispose();
    _viewModel?.removeListener(_onLocationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = EventRecommenderViewModel();
        // Store the viewModel reference and set up the listener
        _viewModel = viewModel;
        viewModel.addListener(_onLocationChanged);
        viewModel.addListener(_checkForErrors);
        return viewModel;
      },
      child: Consumer<EventRecommenderViewModel>(
        builder: (context, viewModel, child) {
          // Do NOT call setState here or functions that call setState
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event Recommender'),
              backgroundColor: Color(0xFF8E97FD),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite),
                  onPressed: () {
                    // Navigate to favorite events screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoriteEventsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body:
                viewModel.isLoading && viewModel.currentLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(context, viewModel),
          );
        },
      ),
    );
  }

  void _checkForErrors() {
    if (_viewModel != null &&
        _viewModel!.shouldShowErrorSnackbar &&
        _viewModel!.error != null) {
      // Show a SnackBar with the error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel!.error!),
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
        _viewModel!.errorSnackbarShown();
      });
    }
  }

  void _onLocationChanged() {
    if (_viewModel == null || _mapController == null) return;

    final currentLocation = _viewModel!.currentLocation;

    // Check if location has actually changed to avoid unnecessary camera updates
    if (currentLocation != null &&
        (_lastLocation == null ||
            _lastLocation!.latitude != currentLocation.latitude ||
            _lastLocation!.longitude != currentLocation.longitude)) {
      _lastLocation = currentLocation;

      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(currentLocation.latitude, currentLocation.longitude),
        ),
      );
    }
  }

  Widget _buildContent(
    BuildContext context,
    EventRecommenderViewModel viewModel,
  ) {
    return Column(
      children: [
        // Search bar for address
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Enter an address',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  debugPrint('address: ${_addressController.text}');
                  if (_addressController.text.isNotEmpty) {
                    debugPrint('1234567890');
                    viewModel.updateLocationByAddress(_addressController.text);
                  }
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),

        // Google Map
        Expanded(
          child:
              viewModel.currentLocation == null
                  ? const Center(child: Text('Location Searching....'))
                  : _buildMap(viewModel),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Save Place'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    const Color.fromARGB(255, 174, 181, 255),
                  ),
                ),
                onPressed: () => _showSavePlaceDialog(context, viewModel),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.event),
                label: const Text('Find Events'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    const Color.fromARGB(255, 174, 181, 255),
                  ),
                ),
                onPressed: () {
                  if (viewModel.currentLocation != null) {
                    //_progressMeterViewModel.showProgressUpdateToast(context, 'recommender');
                    //RecordEntry.insertTimestampToCollection("recommender");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EventListScreen(
                              location: viewModel.currentLocation!,
                            ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(EventRecommenderViewModel viewModel) {
    final currentLocation = viewModel.currentLocation!;
    final cameraPosition = CameraPosition(
      target: LatLng(currentLocation.latitude, currentLocation.longitude),
      zoom: 14.0,
    );

    // Create markers here directly without calling setState
    final markers = {
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentLocation.latitude, currentLocation.longitude),
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: currentLocation.address ?? 'No address available',
        ),
        draggable: true,
        onDragEnd: (LatLng position) {
          // Update location when marker is dragged
          viewModel.updateLocationByCoordinates(position);
        },
      ),
    };

    return Stack(
      children: [
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: cameraPosition,
          markers: markers, // Use the locally created markers
          onMapCreated: (controller) {
            // Using setState here is okay because this is a callback, not during build
            setState(() {
              _mapController = controller;
            });
          },
          onTap: (LatLng position) {
            viewModel.updateLocationByCoordinates(position);
          },
        ),

        // Map type and current location buttons
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'btn1',
                mini: true,
                backgroundColor: Color.fromARGB(255, 174, 181, 255),
                child: const Icon(Icons.layers),
                onPressed: () {
                  // Show map type selector
                  _showMapTypeSelector(context);
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'btn2',
                mini: true,
                backgroundColor: Color.fromARGB(255, 174, 181, 255),
                child: const Icon(Icons.my_location),
                onPressed: () async {
                  // Get the actual current device location
                  await viewModel.refreshCurrentLocation();

                  // If we have a valid location and map controller, animate to it
                  if (viewModel.currentLocation != null &&
                      _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          viewModel.currentLocation!.latitude,
                          viewModel.currentLocation!.longitude,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // Saved places list button
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton(
            heroTag: 'btn3',
            backgroundColor: Color.fromARGB(255, 174, 181, 255),
            child: const Icon(Icons.bookmark),
            onPressed: () {
              // Show saved places
              _showSavedPlaces(context, viewModel);
            },
          ),
        ),
      ],
    );
  }

  void _showMapTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Normal'),
                onTap: () {
                  setState(() {
                    _currentMapType = MapType.normal;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.satellite),
                title: const Text('Satellite'),
                onTap: () {
                  setState(() {
                    _currentMapType = MapType.satellite;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.terrain),
                title: const Text('Terrain'),
                onTap: () {
                  setState(() {
                    _currentMapType = MapType.terrain;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSavePlaceDialog(
    BuildContext context,
    EventRecommenderViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Current Location'),
          content: TextField(
            controller: _placeNameController,
            decoration: const InputDecoration(labelText: 'Place Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (_placeNameController.text.isNotEmpty) {
                  viewModel.saveCurrentPlace(_placeNameController.text);
                  _placeNameController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Place saved successfully')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSavedPlaces(
    BuildContext context,
    EventRecommenderViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This allows the bottom sheet to be larger
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.6, // Use 60% of screen height
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Saved Places',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Expanded(
                  child:
                      viewModel.savedPlaces.isEmpty
                          ? const Center(child: Text('No saved places yet'))
                          : ListView.builder(
                            itemCount: viewModel.savedPlaces.length,
                            itemBuilder: (context, index) {
                              final place = viewModel.savedPlaces[index];
                              return ListTile(
                                title: Text(place.name),
                                subtitle: Text(
                                  place.location.address ?? 'No address',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    viewModel.deleteSavedPlace(place.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Place deleted'),
                                      ),
                                    );
                                  },
                                ),
                                onTap: () {
                                  final location = place.location;
                                  viewModel.updateLocationByCoordinates(
                                    LatLng(
                                      location.latitude,
                                      location.longitude,
                                    ),
                                  );
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLng(
                                        LatLng(
                                          location.latitude,
                                          location.longitude,
                                        ),
                                      ),
                                    );
                                  }
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}