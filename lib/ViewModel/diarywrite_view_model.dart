import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../model/diary_entry.dart';
import '../service/database_service.dart';
import '../service/storage_service.dart';

class DiaryViewModel extends ChangeNotifier {
  final TextEditingController contentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  // User ID passed from the view
  final String currentUserId;

  String? errorMessage;
  String? successMessage;

  bool publicVisibility = false;
  bool dataTracking = false;
  bool isUploading = false;
  bool isImageUploading = false;

  // Store multiple images (with a max limit of 3)
  List<File> imageFiles = [];

  int currentDraftCount = 0;

  // Constructor to accept userId and initialize the draft count
  DiaryViewModel({required this.currentUserId}) {
    _initializeDraftCount();
  }

  // Initialize the draft count when the viewmodel is created
  Future<void> _initializeDraftCount() async {
    try {
      currentDraftCount = await _databaseService.getDraftCount(currentUserId);
      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to load draft count: $e";
      notifyListeners();
    }
  }

  // --- UI handlers ---
  void setContent(String content) {
    contentController.text = content;
    notifyListeners();
  }

  void setVisibility(bool value) {
    publicVisibility = value;
    notifyListeners();
  }

  void setDataTracking(bool value) {
    dataTracking = value;
    notifyListeners();
  }

  void clearImage() {
    imageFiles.clear();
    notifyListeners();
  }
  
  // Remove a specific image by index
  void removeImage(int index) {
    if (index >= 0 && index < imageFiles.length) {
      imageFiles.removeAt(index);
      notifyListeners();
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  // --- Image Picker ---
  Future<void> pickImage({required ImageSource source}) async {
    try {
      if (imageFiles.length >= 3) {
        errorMessage = "You can only upload a maximum of 3 images.";
        notifyListeners();
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        imageFiles.add(File(picked.path)); // Add new image to the list
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Image selection failed: $e";
      notifyListeners();
    }
  }

  // --- Save as draft ---
  Future<void> saveAsDraft() async {
    if (contentController.text.trim().isEmpty) {
      errorMessage = "Please write something before saving.";
      notifyListeners();
      return;
    }

    isUploading = true;
    notifyListeners();

    try {
      final draftCount = await _databaseService.getDraftCount(currentUserId);
      if (draftCount >= 3) {
        errorMessage = "You can only save up to 3 drafts. Current count: $draftCount";
        isUploading = false;
        notifyListeners();
        return;
      }

      String? imageUrl;
      if (imageFiles.isNotEmpty) {
        imageUrl = await _uploadImages(currentUserId); // Upload all images
      }

      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        content: contentController.text,
        imageUrl: imageUrl, // You can store image URLs here as comma-separated or in a list
        publicVisibility: publicVisibility,
        dataTracking: dataTracking,
        isDraft: true,
        userId: currentUserId,
        likedUsers: [],
        likes: 0,
      );

      await _databaseService.uploadDiary(entry);

      currentDraftCount = await _databaseService.getDraftCount(currentUserId);

      contentController.clear();
      imageFiles.clear(); // Clear the image list after saving
      successMessage = "Draft saved successfully. Current draft count: $currentDraftCount";
      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to save draft: $e";
      notifyListeners();
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  // --- Upload images ---
  Future <String?> _uploadImages(String userId) async {
    try {
      isImageUploading = true;
      notifyListeners();

      List<String> uploadedUrls = [];
      for (var file in imageFiles) {
        String? imageUrl = await _storageService.uploadImage(file);
        if (imageUrl != null) {
          uploadedUrls.add(imageUrl);
        }
      }

      // Return a comma-separated string of image URLs (or store as a list in Firestore if needed)
      return uploadedUrls.join(',');
    } catch (e) {
      errorMessage = "Image upload failed: $e";
      return null;
    } finally {
      isImageUploading = false;
      notifyListeners();
    }
  }

  // --- Upload final diary ---
  Future<void> uploadDiary() async {
    if (contentController.text.trim().isEmpty) {
      errorMessage = "Please write something before uploading.";
      notifyListeners();
      return;
    }

    isUploading = true;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFiles.isNotEmpty) {
        imageUrl = await _uploadImages(currentUserId); // Upload all images
      }

      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        content: contentController.text,
        imageUrl: imageUrl, // You can store multiple image URLs here as comma-separated or in a list
        publicVisibility: publicVisibility,
        dataTracking: dataTracking,
        isDraft: false,
        userId: currentUserId,
        likedUsers: [],
        likes: 0,
      );

      await _databaseService.uploadDiary(entry);

      contentController.clear();
      imageFiles.clear(); // Clear the image list after uploading
      publicVisibility = false;
      dataTracking = false;
      successMessage = "Diary uploaded successfully!";
      notifyListeners();
    } catch (e) {
      errorMessage = "Upload failed: $e";
      notifyListeners();
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
}