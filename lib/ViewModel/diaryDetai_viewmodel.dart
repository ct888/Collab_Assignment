import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../service/database_service.dart';
import '../service/storage_service.dart';
import '../model/diary_entry.dart';

class DiaryDetailViewModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  String errorMessage = '';
  List<DiaryEntry> entries = [];


  Future<void> deleteEntry(String entryId) async {
  try {
    final entry = entries.firstWhere((entry) => entry.id == entryId);

    // Delete all images if the imageUrl field contains multiple comma-separated URLs
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      List<String> imageUrls = entry.imageUrl!.split(',');

      for (String url in imageUrls) {
        final trimmedUrl = url.trim();
        if (trimmedUrl.isNotEmpty) {
          await StorageService().deleteImageByUrl(trimmedUrl);
        }
      }
    }
    // Delete the draft from Firestore
    await DatabaseService().deleteDraft(entryId);

    // Remove the entry from local list
    entries.removeWhere((entry) => entry.id == entryId);
    notifyListeners();
  } catch (e) {
    errorMessage = e.toString();
    notifyListeners();
  }
}
}
