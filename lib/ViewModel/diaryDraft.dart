import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry.dart';
import '../service/database_service.dart';
import '../view/dairy_write_screen.dart'; // Make sure this screen exists and accepts a DiaryEntry
import '../service/storage_service.dart';

class DiaryDraftViewModel extends ChangeNotifier {
  List<DiaryEntry> entries = [];
  List<DiaryEntry> draftEntries = [];
  String errorMessage = '';
  bool isLoading = true;
  String? currentUserId;
  String searchQuery = '';
  int filterOption = 0; // 0 for all entries, 1 for public, 2 for private

  final String testUserId = "test_user_123"; // Hardcoded user ID for testing

  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  final List<String> _selectedDrafts = [];
  List<String> get selectedDrafts => _selectedDrafts;

  List<DiaryEntry> get drafts => entries;

  DiaryDraftViewModel() {
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    try {
      isLoading = true;
      notifyListeners();

      currentUserId = testUserId;

      if (currentUserId == null) {
        entries = [];
        draftEntries = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      // Load user entries based on visibility
      entries = await DatabaseService().getUserEntries(
        currentUserId!,
        isDraft: true,
      );

      // Filter shared entries based on visibility and other criteria
      final sharedSnapshot =
          await FirebaseFirestore.instance
              .collection('diary_entries')
              .where('isDraft', isEqualTo: true)
              .get();

      draftEntries =
          sharedSnapshot.docs
              .map(
                (doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where((entry) => entry.userId != currentUserId)
              .toList();

      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedDrafts.clear();
    }
    notifyListeners();
  }

  void toggleDraftSelection(String draftId) {
    if (_selectedDrafts.contains(draftId)) {
      _selectedDrafts.remove(draftId);
    } else {
      _selectedDrafts.add(draftId);
    }
    notifyListeners();
  }


  Future<void> deleteDraft(String entryId) async {
    try {
      final entry = entries.firstWhere((entry) => entry.id == entryId);

      if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
        await StorageService().deleteImageByUrl(entry.imageUrl!);
      }
      await DatabaseService().deleteDraft(entryId);

      entries.removeWhere((entry) => entry.id == entryId);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }


  Future<void> deleteSelectedDrafts() async {
    try {
      for (String draftId in _selectedDrafts) {
        await deleteDraft(draftId);
      }
      _selectedDrafts.clear();
      if (_selectedDrafts.isEmpty && _isSelectionMode) {
        toggleSelectionMode();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void editSelectedDraft(BuildContext context) {
    if (_selectedDrafts.length != 1) return;

    final draftId = _selectedDrafts.first;
    final draft = entries.firstWhere((entry) => entry.id == draftId);

    // Navigate to edit screen
    // This would be implemented with your navigation logic

    // After editing, you might want to reset selection
    _selectedDrafts.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> uploadSelectedDrafts() async {
    try {
      for (String draftId in _selectedDrafts) {
        final draft = entries.firstWhere((entry) => entry.id == draftId);

        // Convert draft to published entry
 //     await DatabaseService().convertDraftToEntry(draft);

        // Remove from drafts
        await deleteDraft(draftId);
      }

      _selectedDrafts.clear();
      if (_isSelectionMode) {
        toggleSelectionMode();
      }

      loadDrafts(); // Refresh the list
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }


  List<DiaryEntry> getSharedEntries() => draftEntries;
}
