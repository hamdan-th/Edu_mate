import 'package:cloud_firestore/cloud_firestore.dart';

class FeedCommentModel {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final Timestamp? createdAt;
  final int likesCount;

  FeedCommentModel({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
    this.likesCount = 0,
  });

  factory FeedCommentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FeedCommentModel(
      commentId: documentId,
      postId: map['postId']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'مستخدم',
      text: map['text']?.toString() ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      likesCount: map['likesCount'] as int? ?? 0,
    );
  }
}
