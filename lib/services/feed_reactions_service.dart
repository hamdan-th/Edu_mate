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

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final data = postSnapshot.data() as Map<String, dynamic>?;
      int currentLikes = data?['likesCount'] as int? ?? 0;

      final likeSnapshot = await transaction.get(docRef);

      if (likeSnapshot.exists) {
        transaction.delete(docRef);
        transaction.update(postRef, {'likesCount': currentLikes > 0 ? currentLikes - 1 : 0});
      } else {
        transaction.set(docRef, {
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likesCount': currentLikes + 1});
      }
    });
  }
}
