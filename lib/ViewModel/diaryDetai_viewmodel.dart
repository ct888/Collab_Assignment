import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry.dart';
import '../service/storage_service.dart';

class DiaryDetailViewModel with ChangeNotifier {
  final FirebaseFirestore _databaseService = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> deleteEntry(DiaryEntry entry) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Validate entry ID
      if (entry.id == null || entry.id.isEmpty) {
        throw ArgumentError('Invalid document ID: Entry ID cannot be null or empty');
      }
      
      // Delete all images if imageUrl field contains multiple comma-separated URLs
      if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
        List<String> imageUrls = entry.imageUrl!.split(',');
        
        for (String url in imageUrls) {
          final trimmedUrl = url.trim();
          if (trimmedUrl.isNotEmpty) {
            try {
              print('Attempting to delete image: $trimmedUrl');
              // Delete individual image
              await _storageService.deleteImage(trimmedUrl);
              print('Successfully deleted image: $trimmedUrl');
            } catch (e) {
              print('Error deleting image: $trimmedUrl - Error: $e');
              // Continue with deletion even if one image fails
            }
          }
        }
      }
      
      print('All images processed, now deleting entry document: ${entry.id}');
      
      // Delete the diary entry document from Firestore
      await _databaseService.collection('diary_entries').doc(entry.id).delete();
      
      print('Successfully deleted entry with ID: ${entry.id}');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in deleteEntry: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      throw e; // Re-throw to let the UI layer handle it
    }
  }
  
  // Helper method for bulk deletion of images
  Future<void> deleteAllImages(String? imageUrls) async {
    if (imageUrls == null || imageUrls.isEmpty) return;
    
    try {
      List<String> urls = imageUrls.split(',');
      for (String url in urls) {
        final trimmedUrl = url.trim();
        if (trimmedUrl.isNotEmpty) {
          await _storageService.deleteImage(trimmedUrl);
        }
      }
    } catch (e) {
      print('Error in deleteAllImages: $e');
      throw e;
    }
  }
}