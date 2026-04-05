import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPostModel {
  final String id;
  final String groupId;
  final String groupName;
  final String authorId;
  final String authorName;
  final String contentText;
  final String contentImageUrl;
  final Timestamp? createdAt;
  final int likesCount;
  final int commentsCount;
  final String visibility;
  final String? collegeId;
  final String? specializationId;

  FeedPostModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.authorId,
    required this.authorName,
    required this.contentText,
    required this.contentImageUrl,
    this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.visibility,
    this.collegeId,
    this.specializationId,
  });

  factory FeedPostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FeedPostModel(
      id: map['postId']?.toString() ?? documentId,
      groupId: map['groupId']?.toString() ?? '',
      groupName: map['groupName']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      contentText: map['contentText']?.toString() ?? '',
      contentImageUrl: map['contentImageUrl']?.toString() ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      likesCount: map['likesCount'] as int? ?? 0,
      commentsCount: map['commentsCount'] as int? ?? 0,
      visibility: map['visibility']?.toString() ?? 'public',
      collegeId: map['collegeId']?.toString(),
      specializationId: map['specializationId']?.toString(),
    );
  }

  bool get isValidPublicPost {
    final hasContent = contentText.trim().isNotEmpty || contentImageUrl.trim().isNotEmpty;
    final hasGroup = groupId.trim().isNotEmpty || groupName.trim().isNotEmpty;
    final isPublic = visibility.toLowerCase() == 'public';
    return hasContent && hasGroup && isPublic;
  }
}
