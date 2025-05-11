import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload an image file to Firebase Storage and return the download URL
  Future<String> uploadImage(File imageFile) async {
    // Create a unique filename using timestamp
    final fileName = 'diary_images/${DateTime.now().millisecondsSinceEpoch}.png';
    
    // Get reference to storage location
    final ref = _storage.ref().child(fileName);
    
    // Upload file
    final uploadTask = ref.putFile(imageFile);
    
    // Wait for upload to complete
    final snapshot = await uploadTask;
    
    // Get download URL
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  }

  // Delete an image from Firebase Storage by URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        return;
      }
      
      
      // Extract the path from the URL
      final ref = _storage.refFromURL(imageUrl);
      
      // Delete the file
      await ref.delete();
    } catch (e) {
      // Handle any errors, such as if the image doesn't exist
      print('Error deleting image: $e');
      // Don't rethrow the exception to prevent app crashes
      // if an individual image deletion fails
    }
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
  final ref = FirebaseStorage.instance.refFromURL(imageUrl);
  await ref.delete();
}
  
  // Delete multiple images (comma-separated URLs)
  Future<void> deleteMultipleImages(String? imageUrls) async {
    if (imageUrls == null || imageUrls.isEmpty) {
      return;
    }
    
    List<String> urls = imageUrls.split(',');
    
    // Process each URL individually
    for (String url in urls) {
      String trimmedUrl = url.trim();
      if (trimmedUrl.isNotEmpty) {
        try {
          await deleteImage(trimmedUrl);
        } catch (e) {
          print('Error deleting image $trimmedUrl: $e');
          // Continue with next image even if one fails
        }
      }
    }
  }
}