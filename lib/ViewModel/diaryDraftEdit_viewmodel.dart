import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../service/database_service.dart';
import '../model/diary_entry.dart';
import 'package:firebase_storage/firebase_storage.dart';


class DiaryDraftEditViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  String currentContent = '';
  bool publicVisibility = false;
  bool dataTracking = false;
  bool isSaving = false;
  String? draftId;
  String? errorMessage;
  String? successMessage;

  // 加载草稿内容
  void loadDraftContent(String content) {
    currentContent = content;
    notifyListeners();
  }

  // 通过ID加载草稿
  Future<void> loadDraftById(String id) async {
    try {
      draftId = id;

      final snapshot =
          await FirebaseFirestore.instance
              .collection(_databaseService.collectionName)
              .doc(id)
              .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final draft = DiaryEntry.fromMap(data);

        currentContent = draft.content ?? '';
        publicVisibility = draft.publicVisibility ?? false;
        dataTracking = draft.dataTracking ?? false;
        notifyListeners();
      } else {
        errorMessage = 'Draft not found';
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error loading draft: $e';
      notifyListeners();
    }
  }

  // 更新内容
  void updateContent(String newContent) {
    currentContent = newContent;
    notifyListeners();
  }

  // 设置可见性
  void setVisibility(bool value) {
    publicVisibility = value;
    notifyListeners();
  }

  // 设置数据追踪
  void setDataTracking(bool value) {
    dataTracking = value;
    notifyListeners();
  }

  // 保存草稿
  /*Future<bool> saveDraft() async {
    if (currentContent.isEmpty) {
      errorMessage = 'Content cannot be empty';
      notifyListeners();
      return false;
    }

    isSaving = true;
    notifyListeners();

    try {
      if (draftId == null) {
        errorMessage = 'Draft ID is null';
        isSaving = false;
        notifyListeners();
        return false;
      }

      // 获取现有草稿数据
      final snapshot =
          await FirebaseFirestore.instance
              .collection(_databaseService.collectionName)
              .doc(draftId)
              .get();

      if (!snapshot.exists) {
        errorMessage = 'Draft not found';
        isSaving = false;
        notifyListeners();
        return false;
      }

      final existingData = snapshot.data() as Map<String, dynamic>;
      final existingDraft = DiaryEntry.fromMap(existingData);

      // 创建更新后的草稿对象
      final updatedDraft = DiaryEntry(
        id: draftId ?? 'default_id', 
        userId: existingDraft.userId,
        content: currentContent,
        date: DateTime.now(),
        publicVisibility: publicVisibility,
        dataTracking: dataTracking,
        isDraft: true,
        imageUrl: existingDraft.imageUrl, 
        likedUsers: existingDraft.likedUsers,
        likes: existingDraft.likes,
      );

      // 更新数据库
      await FirebaseFirestore.instance
          .collection(_databaseService.collectionName)
          .doc(draftId)
          .update(updatedDraft.toMap());

      successMessage = 'Draft saved successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error saving draft: $e';
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
  */

  // 删除草稿
  Future<bool> deleteDraft() async {
    if (draftId == null) {
      return true; 
    }

    isSaving = true;
    notifyListeners();

    try {
      await _databaseService.deleteDraft(draftId!);
      successMessage = 'Draft deleted successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error deleting draft: $e';
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // 清除消息
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<bool> saveDraft({File? imageFile}) async {
  if (currentContent.isEmpty) {
    errorMessage = 'Content cannot be empty';
    notifyListeners();
    return false;
  }

  isSaving = true;
  notifyListeners();

  try {
    if (draftId == null) {
      errorMessage = 'Draft ID is null';
      isSaving = false;
      notifyListeners();
      return false;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(_databaseService.collectionName)
        .doc(draftId)
        .get();

    if (!snapshot.exists) {
      errorMessage = 'Draft not found';
      isSaving = false;
      notifyListeners();
      return false;
    }

    final existingData = snapshot.data() as Map<String, dynamic>;
    final existingDraft = DiaryEntry.fromMap(existingData);
    String? newImageUrl = existingDraft.imageUrl;

    // 如果有新的图片，上传到 Firebase Storage
    if (imageFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('diary_images/${draftId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      newImageUrl = await uploadTask.ref.getDownloadURL();
    }

    final updatedDraft = DiaryEntry(
      id: draftId!,
      userId: existingDraft.userId,
      content: currentContent,
      date: DateTime.now(),
      publicVisibility: publicVisibility,
      dataTracking: dataTracking,
      isDraft: true,
      imageUrl: newImageUrl,
      likedUsers: existingDraft.likedUsers,
      likes: existingDraft.likes,
    );

    await FirebaseFirestore.instance
        .collection(_databaseService.collectionName)
        .doc(draftId)
        .update(updatedDraft.toMap());

    successMessage = 'Draft saved successfully!';
    notifyListeners();
    return true;
  } catch (e) {
    errorMessage = 'Error saving draft: $e';
    notifyListeners();
    return false;
  } finally {
    isSaving = false;
    notifyListeners();
  }
}
}
