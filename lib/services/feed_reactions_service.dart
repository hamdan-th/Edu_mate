import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedReactionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> hasUserLikedPost(String postId) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty) return false;

    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  static Future<void> toggleLike({
    required String postId,
    required bool isCurrentlyLiked,
  }) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty) return;

    final docRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid);
    final postRef = _firestore.collection('posts').doc(postId);

    final batch = _firestore.batch();

    if (isCurrentlyLiked) {
      batch.delete(docRef);
      // Ensure it doesn't go below 0 natively using data checking if possible, but FieldValue.increment(-1) is standard.
      batch.update(postRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      batch.set(docRef, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(postRef, {'likesCount': FieldValue.increment(1)});
    }

    await batch.commit();
  }
}
