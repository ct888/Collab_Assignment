import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry.dart';
import '../service/storage_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'diary_entries';

  // Upload diary entry (either draft or published)
  Future<void> uploadDiary(DiaryEntry entry) async {
    await _firestore.collection(collectionName).doc(entry.id).set(entry.toMap());
  }

  // Get user's diary entries (with optional isDraft filter)
  Future<List<DiaryEntry>> getUserEntries(String userId, {bool? isDraft}) async {
    Query query = _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId);

    if (isDraft != null) {
      query = query.where('isDraft', isEqualTo: isDraft);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Count the user's drafts
  Future<int> getDraftCount(String userId) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .where('isDraft', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }
  
  Future<void> deleteDraft(String entryId) async {
    await _firestore.collection(collectionName).doc(entryId).delete();
  }

  // Delete a draft entry
  // Delete entry and associated images
  Future<void> deleteEntry(String entryId) async {

    try {
      final entryDoc = await _firestore.collection(collectionName).doc(entryId).get();
      if (entryDoc.exists) {
        final entryData = entryDoc.data() as Map<String, dynamic>;
        final entry = DiaryEntry.fromMap(entryData, docId: entryDoc.id);

        if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
          List<String> imageUrls = entry.imageUrl!.split(',');
          for (String imageUrl in imageUrls) {
            await StorageService().deleteImage(imageUrl.trim());
          }
        }

        await _firestore.collection(collectionName).doc(entryId).delete();
      } else {
        print('Entry not found');
      }
    } catch (e) {
      print('Error deleting entry: $e');
    }
  }

  // Get public entries (non-drafts)
  Future<List<DiaryEntry>> getPublicDiaryEntries() async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('publicVisibility', isEqualTo: true)
        .where('isDraft', isEqualTo: false)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
        .toList();
  }

  // Like or unlike a diary entry (transaction safe)
  Future<void> likeEntry(String entryId, String userId) async {
    final entryRef = _firestore.collection(collectionName).doc(entryId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(entryRef);
        if (!snapshot.exists) throw Exception('Entry not found');

        final data = snapshot.data() as Map<String, dynamic>;
        final likedUsers = List<String>.from(data['likedUsers'] ?? []);

        if (likedUsers.contains(userId)) {
          likedUsers.remove(userId); // Unlike
        } else {
          likedUsers.add(userId); // Like
        }

        transaction.update(entryRef, {
          'likedUsers': likedUsers,
          'likes': likedUsers.length,
        });
      });

    } catch (e) {
      print("Error liking entry: $e");
    }
  }

  // Like or unlike an entry
  }

