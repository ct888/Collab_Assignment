/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/database_service.dart';
import '../service/storage_service.dart';
import '../model/diary_entry.dart';


class DiaryEditViewModel extends ChangeNotifier {
  final String diaryId;
  final FirestoreService firestoreService;
  
  DiaryEditViewModel({
    required this.diaryId,
    required this.firestoreService,
  });

  TextEditingController contentController = TextEditingController();
  bool isUploading = false;
  bool isImageUploading = false;
  List<File> imageFiles = [];

  String? errorMessage;
  String? successMessage;

  // Initialize the ViewModel by loading the diary entry
  Future<void> loadDiaryEntry() async {
    try {
      final diaryEntry = await firestoreService.getDiaryEntry(diaryId);
      contentController.text = diaryEntry.content ?? '';
      // Add logic for loading images if they exist
    } catch (e) {
      errorMessage = 'Error loading diary entry: $e';
      notifyListeners();
    }
  }

  // Method to save the edited diary entry
  Future<void> saveDiaryEntry() async {
    if (contentController.text.isEmpty) {
      errorMessage = 'Content cannot be empty.';
      notifyListeners();
      return;
    }

    isUploading = true;
    notifyListeners();

    try {
      await firestoreService.updateDiaryEntry(
        diaryId,
        contentController.text,
        imageFiles,
      );

      successMessage = 'Diary entry updated successfully!';
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error saving diary entry: $e';
      notifyListeners();
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  // Method for image picking
  Future<void> pickImage({required ImageSource source}) async {
    isImageUploading = true;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        imageFiles.add(File(pickedFile.path));
      }
    } catch (e) {
      errorMessage = 'Error picking image: $e';
    } finally {
      isImageUploading = false;
      notifyListeners();
    }
  }

  // Remove selected image
  void removeImage(int index) {
    imageFiles.removeAt(index);
    notifyListeners();
  }

  // Clear error and success messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
*/