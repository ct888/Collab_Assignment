import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/diary_entry.dart';

class BrowseViewModel extends ChangeNotifier {
  final List<DiaryEntry> publicEntries = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String errorMessage = '';

  final int _limit = 10;
  DocumentSnapshot? _lastDocument;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Load public diary entries
  Future<void> loadPublicEntries() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('diary_entries')
          .where('publicVisibility', isEqualTo: true)
          .orderBy('date', descending: true)
          .limit(_limit)
          .get();

      publicEntries.clear();
      publicEntries.addAll(
        querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return DiaryEntry.fromMap(data);
        }),
      );

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      hasMore = querySnapshot.docs.length == _limit;
    } catch (e) {
      errorMessage = 'Failed to load entries: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load more public diary entries for pagination
  Future<void> loadMoreEntries() async {
    if (isLoadingMore || !hasMore || _lastDocument == null) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('diary_entries')
          .where('publicVisibility', isEqualTo: true)
          .orderBy('date', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_limit)
          .get();

      final newEntries = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DiaryEntry.fromMap(data);
      }).toList();

      publicEntries.addAll(newEntries);

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      if (newEntries.length < _limit) {
        hasMore = false;
      }
    } catch (e) {
      errorMessage = 'Failed to load more entries: $e';
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

 /*Future<void> toggleLike(DiaryEntry entry, String userId) async {
  try {
    final entryRef = _firestore.collection('diary_entries').doc(entry.id);
    final likesRef = entryRef.collection('likes').doc(userId);

    final docSnapshot = await likesRef.get();
    bool isAlreadyLiked = docSnapshot.exists;

    if (isAlreadyLiked) {
      await likesRef.delete(); // Unlike
      await removeUserFromLikedUsers(entry, userId); // Remove user from likedUsers
    } else {
      await likesRef.set({'likedAt': FieldValue.serverTimestamp()}); // Like
      await addUserToLikedUsers(entry, userId); // Add user to likedUsers
    }

    await updateLikesCount(entry);
    await refreshEntryLikes(entry);
    notifyListeners();
  } catch (e) {
    print('Error toggling like: $e');
  }
}
*/


Future<void> toggleLike(DiaryEntry entry, String userId) async {
  try {
    final entryRef = _firestore.collection('diary_entries').doc(entry.id);
    final likesRef = entryRef.collection('likes').doc(userId);

    final docSnapshot = await likesRef.get();
    bool isAlreadyLiked = docSnapshot.exists;

    if (isAlreadyLiked) {
      // Unlike
      await likesRef.delete();
      await removeUserFromLikedUsers(entry, userId); // Remove user from likedUsers
      entry.likes--; // Decrease the like count locally
      entry.likedUsers.remove(userId); // Remove the user from likedUsers list
    } else {
      // Like
      await likesRef.set({'likedAt': FieldValue.serverTimestamp()});
      await addUserToLikedUsers(entry, userId); // Add user to likedUsers
      entry.likes++; // Increase the like count locally
      entry.likedUsers.add(userId); // Add the user to likedUsers list
    }

    await updateLikesCount(entry); // Optionally update Firestore like count

    // Refresh the diary entry
    await refreshEntryLikes(entry);

    // Update UI immediately by notifying listeners
    notifyListeners();
  } catch (e) {
    print('Error toggling like: $e');
  }
}


Future<void> addUserToLikedUsers(DiaryEntry entry, String userId) async {
  try {
    final entryRef = _firestore.collection('diary_entries').doc(entry.id);
    await entryRef.update({
      'likedUsers': FieldValue.arrayUnion([userId]),
    });
  } catch (e) {
    print('Error adding user to likedUsers: $e');
  }
}

Future<void> removeUserFromLikedUsers(DiaryEntry entry, String userId) async {
  try {
    final entryRef = _firestore.collection('diary_entries').doc(entry.id);
    await entryRef.update({
      'likedUsers': FieldValue.arrayRemove([userId]),
    });
  } catch (e) {
    print('Error removing user from likedUsers: $e');
  }
}

  Future<void> updateLikesCount(DiaryEntry entry) async {
    try {
      final likesCount = await _firestore
          .collection('diary_entries')
          .doc(entry.id)
          .collection('likes')
          .get()
          .then((snapshot) => snapshot.docs.length);

      await _firestore.collection('diary_entries').doc(entry.id).update({
        'likes': likesCount,
      });
    } catch (e) {
      print('Error updating like count: $e');
    }
  }

  // Refresh the local entry's like count from Firestore
  Future<void> refreshEntryLikes(DiaryEntry entry) async {
    try {
      final entryRef = _firestore.collection('diary_entries').doc(entry.id);
      final updatedEntry = await entryRef.get();

      if (updatedEntry.exists) {
        final updatedData = updatedEntry.data() as Map<String, dynamic>;
        entry.likes = updatedData['likes'] ?? 0; // Update local entry's like count
      }
    } catch (e) {
      print('Error refreshing like count: $e');
    }
  }

  // Get the like count of a diary entry (optional)
  Future<int> getLikesCount(DiaryEntry entry) async {
    try {
      final snapshot = await _firestore
          .collection('diary_entries')
          .doc(entry.id)
          .collection('likes')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
