import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../models/group_message_model.dart';

class GroupService {
  GroupService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }
    return user.uid;
  }

  static CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static Future<DocumentReference<Map<String, dynamic>>> _userRefByUid(
      String uid,
      ) async {
    final directRef = _users.doc(uid);
    final directSnap = await directRef.get();

    if (directSnap.exists) return directRef;

    final query = await _users.where('uid', isEqualTo: uid).limit(1).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    return directRef;
  }

  static Future<String> _userDisplayName(String uid) async {
    final ref = await _userRefByUid(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    return (data['displayName'] ??
        data['fullName'] ??
        data['username'] ??
        _auth.currentUser?.displayName ??
        _auth.currentUser?.email ??
        'User')
        .toString();
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String buildInviteLink({
    required String groupId,
    required String inviteCode,
  }) {
    return 'edumate://invite?groupId=$groupId&code=$inviteCode';
  }

  static Stream<List<GroupModel>> streamMyGroups() {
    final stream = Stream.fromFuture(_userRefByUid(currentUid)).asyncExpand(
          (userRef) {
        return userRef.collection('joined_groups').snapshots().asyncMap(
              (joinedSnap) async {
            final ids = joinedSnap.docs.map((e) => e.id).toSet();

            if (ids.isEmpty) return <GroupModel>[];

            final docs = await Future.wait(ids.map((id) => _groups.doc(id).get()));

            final result = <GroupModel>[];
            for (final doc in docs) {
              try {
                if (!doc.exists) continue;
                final group = GroupModel.fromDoc(doc);
                if (group.id.isNotEmpty && group.isActive) {
                  result.add(group);
                }
              } catch (_) {}
            }

            result.sort((a, b) {
              final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
              final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
              return bTime.compareTo(aTime);
            });

            return result;
          },
        );
      },
    );

    return stream.asBroadcastStream();
  }

  static Stream<List<GroupModel>> streamDiscoverGroups({String search = ''}) {
    final queryText = search.trim().toLowerCase();

    final stream = Stream.fromFuture(_userRefByUid(currentUid)).asyncExpand(
          (userRef) {
        return userRef.collection('joined_groups').snapshots().asyncExpand(
              (joinedSnap) {
            final joinedIds = joinedSnap.docs.map((e) => e.id).toSet();

            return _groups.snapshots().map((snapshot) {
              final result = <GroupModel>[];

              for (final doc in snapshot.docs) {
                try {
                  final group = GroupModel.fromDoc(doc);

                  if (!group.isActive) continue;
                  if (!group.isPublic) continue;
                  if (joinedIds.contains(group.id)) continue;
                  if (group.ownerId == currentUid) continue;

                  if (queryText.isNotEmpty) {
                    final matches = group.name.toLowerCase().contains(queryText) ||
                        group.description.toLowerCase().contains(queryText) ||
                        group.specializationName.toLowerCase().contains(queryText) ||
                        group.collegeName.toLowerCase().contains(queryText);

                    if (!matches) continue;
                  }

                  result.add(group);
                } catch (_) {}
              }

              result.sort((a, b) {
                final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
                final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
                return bTime.compareTo(aTime);
              });

              return result;
            });
          },
        );
      },
    );

    return stream.asBroadcastStream();
  }

  static Future<void> createGroup({
    required String name,
    required String description,
    required String type,
    required String collegeId,
    required String collegeName,
    required String specializationId,
    required String specializationName,
    String imageUrl = '',
  }) async {
    final cleanName = name.trim();
    final cleanDescription = description.trim();
    final nameLowercase = cleanName.toLowerCase();

    if (cleanName.isEmpty) {
      throw Exception('اسم المجموعة مطلوب');
    }

    if (collegeId.trim().isEmpty || collegeName.trim().isEmpty) {
      throw Exception('الكلية مطلوبة');
    }

    if (specializationId.trim().isEmpty || specializationName.trim().isEmpty) {
      throw Exception('التخصص مطلوب');
    }

    final duplicate = await _groups
        .where('nameLowercase', isEqualTo: nameLowercase)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('اسم المجموعة مستخدم بالفعل');
    }

    final userRef = await _userRefByUid(currentUid);
    final displayName = await _userDisplayName(currentUid);
    final groupRef = _groups.doc();

    final inviteCode = _generateInviteCode();
    final inviteLink = buildInviteLink(
      groupId: groupRef.id,
      inviteCode: inviteCode,
    );

    final batch = _db.batch();

    batch.set(groupRef, {
      'groupId': groupRef.id,
      'name': cleanName,
      'groupName': cleanName,
      'nameLowercase': nameLowercase,
      'description': cleanDescription,
      'type': type,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'specializationId': specializationId,
      'specializationName': specializationName,
      'ownerId': currentUid,
      'imageUrl': imageUrl,
      'groupImageUrl': imageUrl,
      'membersCanChat': true,
      'bannedUserIds': <String>[],
      'inviteCode': inviteCode,
      'inviteLink': inviteLink,
      'membersCounts': 1,
      'adminsCount': 1,
      'messagesCount': 0,
      'lastMessageText': '',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(groupRef.collection('members').doc(currentUid), {
      'uid': currentUid,
      'displayName': displayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    batch.set(userRef.collection('joined_groups').doc(groupRef.id), {
      'groupId': groupRef.id,
      'groupName': cleanName,
      'roleInGroup': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
      'type': type,
    });

    await batch.commit();
  }

  static Future<void> joinPublicGroup(String groupId) async {
    final groupRef = _groups.doc(groupId);
    final userRef = await _userRefByUid(currentUid);
    final displayName = await _userDisplayName(currentUid);

    await _db.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final data = groupSnap.data() ?? {};
      final status = (data['status'] ?? 'active').toString();
      final type = (data['type'] ?? 'public').toString();
      final banned = (data['bannedUserIds'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          <String>[];

      if (status != 'active') {
        throw Exception('لا يمكن الانضمام إلى هذه المجموعة');
      }

      if (type != 'public') {
        throw Exception('هذه المجموعة ليست عامة');
      }

      if (banned.contains(currentUid)) {
        throw Exception('أنت محظور من هذه المجموعة');
      }

      final memberRef = groupRef.collection('members').doc(currentUid);
      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) return;

      final groupName = (data['name'] ?? data['groupName'] ?? '').toString();

      tx.set(memberRef, {
        'uid': currentUid,
        'displayName': displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      tx.set(userRef.collection('joined_groups').doc(groupId), {
        'groupId': groupId,
        'groupName': groupName,
        'roleInGroup': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'type': type,
      });

      tx.update(groupRef, {
        'membersCounts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<GroupModel> getGroupByInvite({
    required String groupId,
    required String code,
  }) async {
    final doc = await _groups.doc(groupId).get();

    if (!doc.exists) {
      throw Exception('المجموعة غير موجودة');
    }

    final group = GroupModel.fromDoc(doc);

    if (!group.isPrivate) {
      throw Exception('هذه ليست مجموعة خاصة');
    }

    if (!group.isActive) {
      throw Exception('هذه المجموعة غير متاحة');
    }

    if (group.inviteCode != code.trim().toUpperCase()) {
      throw Exception('رابط الدعوة غير صحيح');
    }

    return group;
  }

  static Future<void> joinPrivateGroupByLink(String inviteLink) async {
    final uri = Uri.tryParse(inviteLink.trim());
    if (uri == null) {
      throw Exception('رابط الدعوة غير صالح');
    }

    final groupId = uri.queryParameters['groupId'];
    final code = uri.queryParameters['code'];

    if ((groupId ?? '').isEmpty || (code ?? '').isEmpty) {
      throw Exception('رابط الدعوة ناقص');
    }

    final group = await getGroupByInvite(groupId: groupId!, code: code!);
    await _joinPrivateGroup(group);
  }

  static Future<void> _joinPrivateGroup(GroupModel group) async {
    final groupRef = _groups.doc(group.id);
    final userRef = await _userRefByUid(currentUid);
    final displayName = await _userDisplayName(currentUid);

    await _db.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final data = groupSnap.data() ?? {};
      final banned = (data['bannedUserIds'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          <String>[];

      if (banned.contains(currentUid)) {
        throw Exception('أنت محظور من هذه المجموعة');
      }

      final memberRef = groupRef.collection('members').doc(currentUid);
      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) return;

      final groupName = (data['name'] ?? data['groupName'] ?? '').toString();

      tx.set(memberRef, {
        'uid': currentUid,
        'displayName': displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      tx.set(userRef.collection('joined_groups').doc(group.id), {
        'groupId': group.id,
        'groupName': groupName,
        'roleInGroup': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'type': 'private',
      });

      tx.update(groupRef, {
        'membersCounts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> leaveGroup(String groupId) async {
    final groupRef = _groups.doc(groupId);
    final userRef = await _userRefByUid(currentUid);

    await _db.runTransaction((tx) async {
      final memberRef = groupRef.collection('members').doc(currentUid);
      final memberSnap = await tx.get(memberRef);

      if (!memberSnap.exists) return;

      final memberData = memberSnap.data() ?? {};
      final role = (memberData['role'] ?? 'member').toString();

      if (role == 'owner') {
        throw Exception('مالك المجموعة لا يمكنه المغادرة قبل نقل الملكية أو حذف المجموعة');
      }

      tx.delete(memberRef);
      tx.delete(userRef.collection('joined_groups').doc(groupId));

      tx.update(groupRef, {
        'membersCounts': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> sendMessage({
    required String groupId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw Exception('لا يمكن إرسال رسالة فارغة');
    }

    final groupRef = _groups.doc(groupId);
    final groupSnap = await groupRef.get();

    if (!groupSnap.exists) {
      throw Exception('المجموعة غير موجودة');
    }

    final groupData = groupSnap.data() ?? {};
    final membersCanChat = (groupData['membersCanChat'] ?? true) == true;
    final banned = (groupData['bannedUserIds'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        <String>[];

    if (banned.contains(currentUid)) {
      throw Exception('أنت محظور من هذه المجموعة');
    }

    final memberRef = groupRef.collection('members').doc(currentUid);
    final memberSnap = await memberRef.get();

    if (!memberSnap.exists) {
      throw Exception('يجب أن تكون عضوًا في المجموعة لإرسال رسالة');
    }

    final memberData = memberSnap.data() ?? {};
    final role = (memberData['role'] ?? 'member').toString();
    final status = (memberData['status'] ?? 'active').toString();

    if (status == 'banned' || banned.contains(currentUid)) {
      throw Exception('أنت محظور من هذه المجموعة');
    }

    if (status == 'muted') {
      throw Exception('تم كتمك داخل هذه المجموعة');
    }

    if (!membersCanChat && role == 'member') {
      throw Exception('المجموعة للقراءة فقط حاليًا');
    }

    final displayName = await _userDisplayName(currentUid);
    final messageRef = groupRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(messageRef, {
      'messageId': messageRef.id,
      'senderId': currentUid,
      'senderName': displayName,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
    });

    batch.update(groupRef, {
      'messagesCount': FieldValue.increment(1),
      'lastMessageText': cleanText,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Stream<List<GroupMessageModel>> streamMessages(String groupId) {
    final stream = _groups
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) {
        try {
          return GroupMessageModel.fromDoc(doc);
        } catch (_) {
          return null;
        }
      })
          .whereType<GroupMessageModel>()
          .toList(),
    );

    return stream.asBroadcastStream();
  }

  static Future<void> saveMessage({
    required String groupId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      print('SAVE DEBUG: groupId=$groupId');
      print('SAVE DEBUG: messageId=$messageId');
      print('SAVE DEBUG: userId=${user.uid}');

      final ref = _groups
          .doc(groupId)
          .collection('savedMessages')
          .doc(user.uid)
          .collection('items')
          .doc(messageId);

      await ref.set({
        ...data,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('SAVE ERROR: $e');
      rethrow;
    }
  }

  static Future<void> unsaveMessage({required String groupId, required String messageId}) async {
    await _groups.doc(groupId).collection('savedMessages').doc(currentUid).collection('items').doc(messageId).delete();
  }

  static Future<bool> isMessageSaved({required String groupId, required String messageId}) async {
    try {
      final doc = await _groups.doc(groupId).collection('savedMessages').doc(currentUid).collection('items').doc(messageId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamSavedMessages(String groupId) {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Stream.value([]);
      
      return _groups.doc(groupId).collection('savedMessages').doc(uid).collection('items').snapshots().map((snap) {
        final list = snap.docs.map((e) => e.data()).toList();
        list.sort((a, b) {
           final aTime = a['savedAt'] as Timestamp?;
           final bTime = b['savedAt'] as Timestamp?;
           if (aTime == null || bTime == null) return 0;
           return bTime.compareTo(aTime);
        });
        return list;
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  static Future<void> promoteToAdmin(String groupId, String memberId) async {
    final memberRef = _groups.doc(groupId).collection('members').doc(memberId);
    final memberDoc = await memberRef.get();
    if (memberDoc.exists && memberDoc.data()?['role'] != 'owner') {
      await memberRef.update({'role': 'admin'});
    }
  }

  static Future<void> removeAdmin(String groupId, String memberId) async {
    final memberRef = _groups.doc(groupId).collection('members').doc(memberId);
    final memberDoc = await memberRef.get();
    if (memberDoc.exists && memberDoc.data()?['role'] != 'owner') {
      await memberRef.update({'role': 'member'});
    }
  }

  static Future<void> muteMember(String groupId, String memberId) async {
    final memberRef = _groups.doc(groupId).collection('members').doc(memberId);
    final memberDoc = await memberRef.get();
    if (memberDoc.exists && memberDoc.data()?['role'] != 'owner') {
      await memberRef.update({'status': 'muted'});
    }
  }

  static Future<void> unmuteMember(String groupId, String memberId) async {
    final memberRef = _groups.doc(groupId).collection('members').doc(memberId);
    final memberDoc = await memberRef.get();
    if (memberDoc.exists) {
      await memberRef.update({'status': 'active'});
    }
  }

  static Future<void> kickMember(String groupId, String memberId) async {
    final groupRef = _groups.doc(groupId);
    final memberRef = groupRef.collection('members').doc(memberId);
    final memberDoc = await memberRef.get();
    
    if (!memberDoc.exists) return;
    if (memberDoc.data()?['role'] == 'owner') throw Exception("لا يمكن طرد المالك");

    final batch = _db.batch();
    batch.delete(memberRef);
    batch.delete(_users.doc(memberId).collection('joined_groups').doc(groupId));
    batch.update(groupRef, {'membersCounts': FieldValue.increment(-1)});
    await batch.commit();
  }

  static Future<void> reportMember(String groupId, String reportedUserId) async {
    await _db.collection('reports').add({
      'groupId': groupId,
      'reportedUserId': reportedUserId,
      'reporterUserId': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> publishGlobalFeedPost({
    required GroupModel group,
    required String text,
    String? imageUrl,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      throw Exception('لا يمكن نشر محتوى فارغ');
    }

    final displayName = await _userDisplayName(currentUid);
    final batch = _db.batch();

    final postRef = _db.collection('posts').doc();

    batch.set(postRef, {
      'id': postRef.id,
      'groupId': group.id,
      'groupName': group.name,
      'groupImageUrl': group.imageUrl,
      'authorUserId': currentUid,
      'authorName': displayName,
      'content': cleanText,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'group_public',
    });

    await batch.commit();
  }
}