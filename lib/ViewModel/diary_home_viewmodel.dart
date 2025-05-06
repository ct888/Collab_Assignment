import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry.dart';
import '../service/database_service.dart';
import '../service/storage_service.dart';

class DiaryHomeViewModel extends ChangeNotifier {
  List<DiaryEntry> entries = [];
  List<DiaryEntry> sharedEntries = [];
  String errorMessage = '';
  bool isLoading = true;
  String? currentUserId;
  String searchQuery = '';
  int filterOption = 0; // 0 = all, 1 = public only, 2 = private only

  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  // Modify constructor to accept userId dynamically
  DiaryHomeViewModel({required this.currentUserId}) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    try {
      isLoading = true;
      notifyListeners();

      if (currentUserId == null) {
        entries = [];
        sharedEntries = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      // Load user entries (non-drafts only)
      entries = await _databaseService.getUserEntries(currentUserId!, isDraft: false);

      // Load shared entries (other users, visible, and non-drafts)
      final sharedSnapshot = await FirebaseFirestore.instance
          .collection('diary_entries')
          .where('publicVisibility', isEqualTo: _getVisibilityFilter())
          .where('isDraft', isEqualTo: false)
          .get();

      sharedEntries = sharedSnapshot.docs
          .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
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

  bool _getVisibilityFilter() {
    if (filterOption == 1) return true;  // public
    if (filterOption == 2) return false; // private
    return true; // default: public for shared entries
  }

  void searchEntries(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Map<String, List<DiaryEntry>> getEntriesByMonth() {
    final Map<String, List<DiaryEntry>> grouped = {};
    final filtered = _applyFilters(entries);

    for (var entry in filtered) {
      final key = DateFormat.yMMMM().format(entry.date);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return grouped;
  }

  List<DiaryEntry> _applyFilters(List<DiaryEntry> all) {
    return all
        .where((entry) => entry.content.toLowerCase().contains(searchQuery.toLowerCase()))
        .where((entry) => filterOption == 0 || entry.publicVisibility == (filterOption == 1))
        .toList();
  }

  void setFilterOption(int option) {
    filterOption = option;
    loadEntries();
  }

  List<DiaryEntry> getSharedEntries() => sharedEntries;

  Future<void> deleteImage(String imageUrl) async {
    try {
      await _storageService.deleteImage(imageUrl);
    } catch (e) {
      print('Error in deleteImage: $e');
    }
  }
}
