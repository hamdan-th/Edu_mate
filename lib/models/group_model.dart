import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String nameLowercase;
  final String description;
  final String type;

  final String collegeId;
  final String collegeName;

  final String specializationId;
  final String specializationName;

  final String ownerId;
  final String imageUrl;
  final bool membersCanChat;
  final List<String> bannedUserIds;
  final String inviteCode;
  final String inviteLink;
  final String status;
  final int membersCounts;
  final int adminsCount;
  final int messagesCount;
  final String lastMessageText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.nameLowercase,
    required this.description,
    required this.type,
    required this.collegeId,
    required this.collegeName,
    required this.specializationId,
    required this.specializationName,
    required this.ownerId,
    required this.imageUrl,
    required this.membersCanChat,
    required this.bannedUserIds,
    required this.inviteCode,
    required this.inviteLink,
    required this.status,
    required this.membersCounts,
    required this.adminsCount,
    required this.messagesCount,
    required this.lastMessageText,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublic => type == 'public';
  bool get isPrivate => type == 'private';
  bool get isActive => status == 'active';

  factory GroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return GroupModel(
      id: doc.id,
      name: (data['name'] ?? data['groupName'] ?? '').toString(),
      nameLowercase: (data['nameLowercase'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      type: (data['type'] ?? 'public').toString(),
      collegeId: (data['collegeId'] ?? '').toString(),
      collegeName: (data['collegeName'] ?? '').toString(),
      specializationId: (data['specializationId'] ?? '').toString(),
      specializationName: (data['specializationName'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? data['groupImageUrl'] ?? '').toString(),
      membersCanChat: (data['membersCanChat'] ?? true) == true,
      bannedUserIds: _toStringList(data['bannedUserIds']),
      inviteCode: (data['inviteCode'] ?? '').toString(),
      inviteLink: (data['inviteLink'] ?? '').toString(),
      status: (data['status'] ?? 'active').toString(),
      membersCounts: (data['membersCounts'] as num?)?.toInt() ?? 0,
      adminsCount: (data['adminsCount'] as num?)?.toInt() ?? 0,
      messagesCount: (data['messagesCount'] as num?)?.toInt() ?? 0,
      lastMessageText: (data['lastMessageText'] ?? '').toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }
}