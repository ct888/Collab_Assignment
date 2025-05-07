import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry.dart';
import '../service/database_service.dart';
import '../service/storage_service.dart';
import '../view/draftEdit.dart';  // 导入我们创建的编辑屏幕

class DiaryDraftViewModel extends ChangeNotifier {
  List<DiaryEntry> entries = [];
  List<DiaryEntry> draftEntries = [];
  String errorMessage = '';
  bool isLoading = true;
  String? currentUserId;
  String searchQuery = '';
  int filterOption = 0; // 0 for all entries, 1 for public, 2 for private
  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  final List<String> _selectedDrafts = [];
  List<String> get selectedDrafts => _selectedDrafts;

  List<DiaryEntry> get drafts => entries;

  DiaryDraftViewModel({required this.currentUserId}) {
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    try {
      isLoading = true;
      notifyListeners();

      if (currentUserId == null || currentUserId!.isEmpty) {
        entries = [];
        draftEntries = [];
        isLoading = false;
        notifyListeners();
        return;
      }

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

  // 更新编辑草稿的方法
  void editSelectedDraft(BuildContext context) async {
    if (_selectedDrafts.length != 1) return;

    final draftId = _selectedDrafts.first;
    final draft = entries.firstWhere((entry) => entry.id == draftId);

    // 导航到编辑屏幕
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDraftEditScreen(draft: draft),
      ),
    );

    // 如果编辑成功，刷新草稿列表
    if (result == true) {
      await loadDrafts();
    }

    // 在编辑后重置选择模式
    _selectedDrafts.clear();
    if (_isSelectionMode) {
      toggleSelectionMode();
    }
    notifyListeners();
  }

  Future<void> uploadSelectedDrafts() async {
    try {
      for (String draftId in _selectedDrafts) {
        final draft = entries.firstWhere((entry) => entry.id == draftId);

        // 转换草稿为已发布条目
        // 更新isDraft字段为false，并设置为公开条目
        final publishedEntry = DiaryEntry(
          id: draft.id,
          userId: draft.userId,
          content: draft.content,
          date: draft.date,
          publicVisibility: true, // 设置为公开
          dataTracking: draft.dataTracking,
          isDraft: false, // 不再是草稿
          imageUrl: draft.imageUrl,
          likedUsers: draft.likedUsers,
          likes: draft.likes,
        );
        
        // 更新数据库
        await FirebaseFirestore.instance
            .collection(DatabaseService().collectionName)
            .doc(draft.id)
            .update(publishedEntry.toMap());
      }

      _selectedDrafts.clear();
      if (_isSelectionMode) {
        toggleSelectionMode();
      }

      loadDrafts(); // 刷新列表
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<DiaryEntry> getSharedEntries() => draftEntries;
}