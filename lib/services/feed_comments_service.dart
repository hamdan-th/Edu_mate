import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_comment_model.dart';
import '../models/feed_comment_reply_model.dart';
import 'notifications_service.dart';
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

    final postSnapshot = await postRef.get();
    final postData = postSnapshot.data();

    final postAuthorId = (postData?['authorId'] ?? '').toString();

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

    if (postAuthorId.isNotEmpty && postAuthorId != user.uid) {
      await NotificationsService.createNotification(
        userId: postAuthorId,
        title: 'تعليق جديد على منشورك',
        body: '$authorName علّق على منشورك',
        type: 'general',
        subType: 'feed_comment_new',
        senderName: authorName,
        senderId: user.uid,
        postId: postId,
      );
    }
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
    String? replyToUserId,
    String? replyToUserName,
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

    final data = <String, dynamic>{
      'commentId': commentId,
      'authorId': user.uid,
      'authorName': authorName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (replyToUserId != null) data['replyToUserId'] = replyToUserId;
    if (replyToUserName != null) data['replyToUserName'] = replyToUserName;

    await replyRef.set(data);

    if (replyToUserId != null &&
        replyToUserId.isNotEmpty &&
        replyToUserId != user.uid) {
      await NotificationsService.createNotification(
        userId: replyToUserId,
        title: 'رد جديد على تعليقك',
        body: '$authorName رد على تعليقك',
        type: 'general',
        subType: 'feed_reply_new',
        senderName: authorName,
        senderId: user.uid,
        postId: postId,
      );
    }
  }

  static Future<void> editComment({
    required String postId,
    required String commentId,
    required String newText,
  }) async {
    if (postId.isEmpty || commentId.isEmpty || newText.trim().isEmpty) return;
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({'text': newText.trim()});
  }

  static Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    if (postId.isEmpty || commentId.isEmpty) return;
    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);
    
    final batch = _firestore.batch();
    batch.delete(commentRef);
    batch.update(postRef, {'commentsCount': FieldValue.increment(-1)}); // Approximation safety
    await batch.commit();
  }

  static Future<void> editReply({
    required String postId,
    required String commentId,
    required String replyId,
    required String newText,
  }) async {
    if (postId.isEmpty || commentId.isEmpty || replyId.isEmpty || newText.trim().isEmpty) return;
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .update({'text': newText.trim()});
  }

  static Future<void> deleteReply({
    required String postId,
    required String commentId,
    required String replyId,
  }) async {
    if (postId.isEmpty || commentId.isEmpty || replyId.isEmpty) return;
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .delete();
  }
}
