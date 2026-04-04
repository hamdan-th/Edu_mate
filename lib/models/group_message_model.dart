import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;

  GroupMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
  });

  factory GroupMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return GroupMessageModel(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? 'User').toString(),
      text: (data['text'] ?? '').toString(),
      imageUrl: data['imageUrl']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      replyToMessageId: data['replyToMessageId']?.toString() ?? data['replyToId']?.toString(),
      replyToText: data['replyToText']?.toString(),
      replyToSenderName: data['replyToSenderName']?.toString() ?? data['replyToSender']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}