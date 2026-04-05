import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedCommentReactionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> hasUserLikedComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty || commentId.isEmpty) return false;

    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  static Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required bool isCurrentlyLiked,
  }) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty || commentId.isEmpty) return;

    final docRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(user.uid);
        
    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final batch = _firestore.batch();

    if (isCurrentlyLiked) {
      batch.delete(docRef);
      batch.update(commentRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      batch.set(docRef, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(commentRef, {'likesCount': FieldValue.increment(1)});
    }

    await batch.commit();
  }

  static Future<void> reportComment({
    required String postId,
    required String commentId,
    required String reportedCommentAuthorId,
    required String commentText,
  }) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty || commentId.isEmpty) return;

    await _firestore.collection('comment_reports').add({
      'postId': postId,
      'commentId': commentId,
      'reportedCommentAuthorId': reportedCommentAuthorId,
      'reporterUserId': user.uid,
      'commentText': commentText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
