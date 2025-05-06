// services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../Model/location.dart'; // Your Location model

class LocationService {
  Future<Location> getCurrentLocation() async {
    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }
    
    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    
    // Get address using geocoding
    List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
      position.latitude, 
      position.longitude
    );
    
    String? address;
    if (placemarks.isNotEmpty) {
      geo.Placemark place = placemarks[0];
      address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
    }
    
    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }
  
Future<Location> getLocationFromAddress(String address) async {
  try {
    List<geo.Location> locations = await geo.locationFromAddress(address);
    if (locations.isEmpty) {
      throw Exception('Could not find location for this address');
    }
    
    // Get a proper address format from the coordinates
    String? formattedAddress = await getAddressFromCoordinates(
      locations[0].latitude,
      locations[0].longitude
    );
    
    return Location(
      latitude: locations[0].latitude,
      longitude: locations[0].longitude,
      address: formattedAddress ?? address,
    );
  } catch (e) {
    throw Exception('Could not find location for this address: $e');
  }
}
  
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }
}