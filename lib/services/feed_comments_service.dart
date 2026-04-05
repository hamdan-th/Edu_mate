import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_comment_model.dart';
import '../models/feed_comment_reply_model.dart';

class FeedCommentsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<List<FeedCommentModel>> streamComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedCommentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty || text.trim().isEmpty) return;

    // Fetch user name as a fallback gracefully
    String authorName = 'مستخدم';
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        authorName = (data?['username'] ?? data?['fullName'] ?? data?['displayName'] ?? 'مستخدم').toString();
      }
    } catch (_) {}

    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    final batch = _firestore.batch();

    batch.set(commentRef, {
      'postId': postId,
      'authorId': user.uid,
      'authorName': authorName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(postRef, {'commentsCount': FieldValue.increment(1)});

    await batch.commit();
  }

  static Stream<List<FeedCommentReplyModel>> streamReplies({
    required String postId,
    required String commentId,
  }) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false) // Replies usually top-to-bottom
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedCommentReplyModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<void> addReply({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null || postId.isEmpty || commentId.isEmpty || text.trim().isEmpty) return;

    String authorName = 'مستخدم';
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        authorName = (data?['username'] ?? data?['fullName'] ?? data?['displayName'] ?? 'مستخدم').toString();
      }
    } catch (_) {}

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
        
    final replyRef = commentRef.collection('replies').doc();

    await replyRef.set({
      'commentId': commentId,
      'authorId': user.uid,
      'authorName': authorName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
