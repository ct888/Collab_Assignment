import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../service/storage_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'diary_entries';

  // Hardcoded user ID for testing
  final String testUserId = "test_user_126";

  // Upload diary entry (either draft or published)
  Future<void> uploadDiary(DiaryEntry entry) async {
    // For testing, print the entry details
    print('Uploading entry: ID=${entry.id}, isDraft=${entry.isDraft}');
    
    await _firestore
        .collection(collectionName)
        .doc(entry.id)
        .set(entry.toMap());
  }

  // Get user's diary entries
  Future<List<DiaryEntry>> getUserEntries(String userId, {bool? isDraft}) async {
    // Use hardcoded user ID for testing
    userId = testUserId;
    
    Query query = _firestore.collection(collectionName).where('userId', isEqualTo: userId);
    
    if (isDraft != null) {
      query = query.where('isDraft', isEqualTo: isDraft);
    }
    
    final snapshot = await query.get();
    
    // For testing, print the number of entries found
    print('Found ${snapshot.docs.length} entries for user $userId (isDraft=${isDraft})');
    
    return snapshot.docs
        .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<int> getDraftCount(String userId) async {
    // Use hardcoded user ID for testing
    userId = testUserId;
    
    final snapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .where('isDraft', isEqualTo: true)
        .get();
    print('Current draft count for user $userId: ${snapshot.docs.length}');
    
    return snapshot.docs.length;
  }

  // Delete a draft
  Future<void> deleteDraft(String entryId) async {
    print('Deleting draft: $entryId');
    
    await _firestore
        .collection(collectionName)
        .doc(entryId)
        .delete();
  }

  Future<void> deleteEntry(String entryId) async {
    print('Deleting entry: $entryId');
  
    try {
      // Fetch the diary entry before deletion to access image URLs
      final entryDoc = await _firestore.collection(collectionName).doc(entryId).get();
      if (entryDoc.exists) {
        final entryData = entryDoc.data() as Map<String, dynamic>;
        final entry = DiaryEntry.fromMap(entryData);

        // Delete associated images if available
        if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
          List<String> imageUrls = entry.imageUrl!.split(',');
          for (String imageUrl in imageUrls) {
            await StorageService().deleteImage(imageUrl.trim());
          }
        }
        
        // Now delete the entry from Firestore
        await _firestore.collection(collectionName).doc(entryId).delete();
        print('Entry deleted successfully');
      } else {
        print('Entry not found');
      }
    } catch (e) {
      print('Error deleting entry: $e');
    }
  }

  Future<List<DiaryEntry>> getPublicDiaryEntries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('diary_entries')
        .where('publicVisibility', isEqualTo: true)
        .where('isDraft', isEqualTo: false)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Like or unlike an entry
  Future<void> likeEntry(String entryId, String userId) async {
    try {
      final entryRef = _firestore.collection(collectionName).doc(entryId);

      // Fetch the diary entry
      final entryDoc = await entryRef.get();
      if (!entryDoc.exists) {
        print('Entry not found');
        return;
      }

      final entryData = entryDoc.data() as Map<String, dynamic>;
      final entry = DiaryEntry.fromMap(entryData);

      // If likedUsers is present, toggle the like status
      if (entryData.containsKey('likedUsers')) {
        final likedUsers = List<String>.from(entryData['likedUsers']);
        if (likedUsers.contains(userId)) {
          // User has already liked, remove like
          likedUsers.remove(userId);
        } else {
          // User has not liked, add like
          likedUsers.add(userId);
        }

        await entryRef.update({
          'likedUsers': likedUsers,
          'likes': likedUsers.length,
        });
      } else {
        // If no likedUsers, initialize it
        await entryRef.update({
          'likedUsers': [userId],
          'likes': 1,
        });
      }

      print('Like action successful');
    } catch (e) {
      print("Error liking entry: $e");
    }
  }
}
