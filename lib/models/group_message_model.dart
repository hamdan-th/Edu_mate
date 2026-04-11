import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;

  final bool sharedFromLibrary;
  final String? sharedFileId;
  final String? sharedFileTitle;
  final String? sharedFileUrl;
  final String? sharedFileType;
  final String? sharedFileOwnerId;
  final String? sharedFileThumbnailUrl;

  GroupMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    this.imageUrl,
    required this.createdAt,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.sharedFromLibrary = false,
    this.sharedFileId,
    this.sharedFileTitle,
    this.sharedFileUrl,
    this.sharedFileType,
    this.sharedFileOwnerId,
    this.sharedFileThumbnailUrl,
  });

  bool get isLibraryFileLink => type == 'library_file_link';

  factory GroupMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return GroupMessageModel(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? 'User').toString(),
      text: (data['text'] ?? '').toString(),
      type: (data['type'] ?? 'text').toString(),
      imageUrl: data['imageUrl']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      replyToMessageId:
      data['replyToMessageId']?.toString() ?? data['replyToId']?.toString(),
      replyToText: data['replyToText']?.toString(),
      replyToSenderName: data['replyToSenderName']?.toString() ??
          data['replyToSender']?.toString(),
      sharedFromLibrary: data['sharedFromLibrary'] == true,
      sharedFileId: data['sharedFileId']?.toString(),
      sharedFileTitle: data['sharedFileTitle']?.toString(),
      sharedFileUrl: data['sharedFileUrl']?.toString(),
      sharedFileType: data['sharedFileType']?.toString(),
      sharedFileOwnerId: data['sharedFileOwnerId']?.toString(),
      sharedFileThumbnailUrl: data['sharedFileThumbnailUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      'sharedFromLibrary': sharedFromLibrary,
      if (sharedFileId != null) 'sharedFileId': sharedFileId,
      if (sharedFileTitle != null) 'sharedFileTitle': sharedFileTitle,
      if (sharedFileUrl != null) 'sharedFileUrl': sharedFileUrl,
      if (sharedFileType != null) 'sharedFileType': sharedFileType,
      if (sharedFileOwnerId != null) 'sharedFileOwnerId': sharedFileOwnerId,
      if (sharedFileThumbnailUrl != null)
        'sharedFileThumbnailUrl': sharedFileThumbnailUrl,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}