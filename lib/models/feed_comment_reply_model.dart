import 'package:cloud_firestore/cloud_firestore.dart';

class FeedCommentReplyModel {
  final String replyId;
  final String commentId;
  final String authorId;
  final String authorName;
  final String text;
  final Timestamp? createdAt;

  FeedCommentReplyModel({
    required this.replyId,
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  factory FeedCommentReplyModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FeedCommentReplyModel(
      replyId: documentId,
      commentId: map['commentId']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'مستخدم',
      text: map['text']?.toString() ?? '',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}
