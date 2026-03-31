import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }
    return user;
  }

  static String get uid => _currentUser.uid;

  static CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static Future<DocumentReference<Map<String, dynamic>>> _findUserDocRefByUid(
      String userId,
      ) async {
    final byIdRef = _users.doc(userId);
    final byIdSnap = await byIdRef.get();

    if (byIdSnap.exists) return byIdRef;

    final query = await _users.where('uid', isEqualTo: userId).limit(1).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    return byIdRef;
  }

  static Future<String> _getUserDisplayName(String userId) async {
    final userRef = await _findUserDocRefByUid(userId);
    final snap = await userRef.get();
    final data = snap.data() ?? {};

    return (data['displayName'] ??
        data['fullName'] ??
        data['username'] ??
        (userId == uid ? _currentUser.displayName : null) ??
        (userId == uid ? _currentUser.email : null) ??
        'User')
        .toString();
  }

  static Future<void> createGroup({
    required String name,
    required String description,
    required String specializationId,
    required String specializationName,
    String type = 'public',
    String? groupImageUrl,
  }) async {
    final cleanName = name.trim();
    final cleanDescription = description.trim();

    if (cleanName.isEmpty) {
      throw Exception('اسم المجموعة مطلوب');
    }

    final groupRef = _groups.doc();
    final userRef = await _findUserDocRefByUid(uid);
    final displayName = await _getUserDisplayName(uid);
    final inviteCode = groupRef.id.substring(0, 6).toUpperCase();

    final memberRef = groupRef.collection('members').doc(uid);
    final joinedGroupRef = userRef.collection('joined_groups').doc(groupRef.id);

    final batch = _firestore.batch();

    batch.set(groupRef, {
      'groupId': groupRef.id,
      'name': cleanName,
      'groupName': cleanName,
      'description': cleanDescription,
      'specializationId': specializationId,
      'specializationName': specializationName,
      'ownerId': uid,
      'groupImageUrl': groupImageUrl ?? '',
      'membersCounts': 1,
      'adminsCount': 1,
      'messagesCount': 0,
      'lastMessageText': '',
      'inviteCode': inviteCode,
      'type': type,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(memberRef, {
      'uid': uid,
      'displayName': displayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.set(joinedGroupRef, {
      'groupId': groupRef.id,
      'groupName': cleanName,
      'roleInGroup': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
      'type': type,
    });

    await batch.commit();
  }

  static Future<void> joinGroup(String groupId) async {
    final groupRef = _groups.doc(groupId);
    final userRef = await _findUserDocRefByUid(uid);
    final displayName = await _getUserDisplayName(uid);

    await _firestore.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final groupData = groupSnap.data() ?? {};
      final status = (groupData['status'] ?? 'active').toString();
      final type = (groupData['type'] ?? 'public').toString();

      if (status != 'active') {
        throw Exception('لا يمكن الانضمام إلى هذه المجموعة');
      }

      if (type == 'private') {
        throw Exception('هذه مجموعة خاصة - الانضمام عبر دعوة فقط');
      }

      final memberRef = groupRef.collection('members').doc(uid);
      final joinedGroupRef = userRef.collection('joined_groups').doc(groupId);

      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) return;

      final groupName =
      (groupData['name'] ?? groupData['groupName'] ?? '').toString();

      tx.set(memberRef, {
        'uid': uid,
        'displayName': displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      tx.set(joinedGroupRef, {
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

  static Future<void> joinPrivateGroupWithInvite({
    required String groupId,
    required String inviteCode,
  }) async {
    final groupRef = _groups.doc(groupId);
    final userRef = await _findUserDocRefByUid(uid);
    final displayName = await _getUserDisplayName(uid);

    await _firestore.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final groupData = groupSnap.data() ?? {};
      final status = (groupData['status'] ?? 'active').toString();
      final type = (groupData['type'] ?? 'public').toString();
      final realInviteCode = (groupData['inviteCode'] ?? '').toString();

      if (status != 'active') {
        throw Exception('لا يمكن الانضمام إلى هذه المجموعة');
      }

      if (type != 'private') {
        throw Exception('هذه المجموعة ليست خاصة');
      }

      if (realInviteCode.isEmpty || realInviteCode != inviteCode.trim()) {
        throw Exception('كود الدعوة غير صحيح');
      }

      final memberRef = groupRef.collection('members').doc(uid);
      final joinedGroupRef = userRef.collection('joined_groups').doc(groupId);

      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) return;

      final groupName =
      (groupData['name'] ?? groupData['groupName'] ?? '').toString();

      tx.set(memberRef, {
        'uid': uid,
        'displayName': displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      tx.set(joinedGroupRef, {
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

  static Future<void> leaveGroup(String groupId) async {
    final groupRef = _groups.doc(groupId);
    final userRef = await _findUserDocRefByUid(uid);

    await _firestore.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) return;

      final memberRef = groupRef.collection('members').doc(uid);
      final joinedGroupRef = userRef.collection('joined_groups').doc(groupId);

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final memberData = memberSnap.data() ?? {};
      final role = (memberData['role'] ?? 'member').toString();

      if (role == 'owner') {
        throw Exception('مالك المجموعة لا يمكنه المغادرة قبل نقل الملكية أو حذف المجموعة');
      }

      tx.delete(memberRef);
      tx.delete(joinedGroupRef);

      final updates = <String, dynamic>{
        'membersCounts': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'admin') {
        updates['adminsCount'] = FieldValue.increment(-1);
      }

      tx.update(groupRef, updates);
    });
  }

  static Future<void> sendMessage({
    required String groupId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw Exception('لا يمكن إرسال رسالة فارغة');
    }

    final groupRef = _groups.doc(groupId);
    final memberRef = groupRef.collection('members').doc(uid);
    final memberSnap = await memberRef.get();

    if (!memberSnap.exists) {
      throw Exception('يجب أن تكون عضوًا في المجموعة لإرسال رسالة');
    }

    final displayName = await _getUserDisplayName(uid);
    final messageRef = groupRef.collection('messages').doc();

    final batch = _firestore.batch();

    batch.set(messageRef, {
      'messageId': messageRef.id,
      'senderId': uid,
      'senderName': displayName,
      'text': cleanText,
      'messageType': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(groupRef, {
      'messagesCount': FieldValue.increment(1),
      'lastMessageText': cleanText,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> makeAdmin(String groupId, String userId) async {
    final groupRef = _groups.doc(groupId);
    final targetUserRef = await _findUserDocRefByUid(userId);

    await _firestore.runTransaction((tx) async {
      final memberRef = groupRef.collection('members').doc(userId);
      final joinedGroupRef =
      targetUserRef.collection('joined_groups').doc(groupId);

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) {
        throw Exception('العضو غير موجود في المجموعة');
      }

      final data = memberSnap.data() ?? {};
      final currentRole = (data['role'] ?? 'member').toString();

      if (currentRole == 'owner' || currentRole == 'admin') return;

      tx.update(memberRef, {'role': 'admin'});
      tx.set(
        joinedGroupRef,
        {'roleInGroup': 'admin'},
        SetOptions(merge: true),
      );

      tx.update(groupRef, {
        'adminsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> removeAdmin(String groupId, String userId) async {
    final groupRef = _groups.doc(groupId);
    final targetUserRef = await _findUserDocRefByUid(userId);

    await _firestore.runTransaction((tx) async {
      final memberRef = groupRef.collection('members').doc(userId);
      final joinedGroupRef =
      targetUserRef.collection('joined_groups').doc(groupId);

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) {
        throw Exception('العضو غير موجود في المجموعة');
      }

      final data = memberSnap.data() ?? {};
      final currentRole = (data['role'] ?? 'member').toString();

      if (currentRole == 'owner') {
        throw Exception('لا يمكن إزالة صلاحية المالك');
      }

      if (currentRole != 'admin') return;

      tx.update(memberRef, {'role': 'member'});
      tx.set(
        joinedGroupRef,
        {'roleInGroup': 'member'},
        SetOptions(merge: true),
      );

      tx.update(groupRef, {
        'adminsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    final groupRef = _groups.doc(groupId);
    final currentOwnerRef = await _findUserDocRefByUid(uid);
    final newOwnerUserRef = await _findUserDocRefByUid(newOwnerId);

    await _firestore.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final groupData = groupSnap.data() ?? {};
      final ownerId = (groupData['ownerId'] ?? '').toString();

      if (ownerId != uid) {
        throw Exception('فقط مالك المجموعة يمكنه نقل الملكية');
      }

      if (uid == newOwnerId) return;

      final currentOwnerMemberRef = groupRef.collection('members').doc(uid);
      final newOwnerMemberRef = groupRef.collection('members').doc(newOwnerId);

      final currentOwnerMemberSnap = await tx.get(currentOwnerMemberRef);
      final newOwnerMemberSnap = await tx.get(newOwnerMemberRef);

      if (!currentOwnerMemberSnap.exists || !newOwnerMemberSnap.exists) {
        throw Exception('العضو غير موجود داخل المجموعة');
      }

      tx.update(currentOwnerMemberRef, {'role': 'admin'});
      tx.update(newOwnerMemberRef, {'role': 'owner'});

      tx.set(
        currentOwnerRef.collection('joined_groups').doc(groupId),
        {'roleInGroup': 'admin'},
        SetOptions(merge: true),
      );

      tx.set(
        newOwnerUserRef.collection('joined_groups').doc(groupId),
        {'roleInGroup': 'owner'},
        SetOptions(merge: true),
      );

      tx.update(groupRef, {
        'ownerId': newOwnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> removeMember(String groupId, String userId) async {
    final groupRef = _groups.doc(groupId);
    final targetUserRef = await _findUserDocRefByUid(userId);

    await _firestore.runTransaction((tx) async {
      final memberRef = groupRef.collection('members').doc(userId);
      final joinedGroupRef =
      targetUserRef.collection('joined_groups').doc(groupId);

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final memberData = memberSnap.data() ?? {};
      final role = (memberData['role'] ?? 'member').toString();

      if (role == 'owner') {
        throw Exception('لا يمكن طرد مالك المجموعة');
      }

      tx.delete(memberRef);
      tx.delete(joinedGroupRef);

      final updates = <String, dynamic>{
        'membersCounts': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'admin') {
        updates['adminsCount'] = FieldValue.increment(-1);
      }

      tx.update(groupRef, updates);
    });
  }

  static Future<void> deleteGroup(String groupId) async {
    await _groups.doc(groupId).update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateGroup({
    required String groupId,
    required String name,
    required String description,
    String? type,
    String? groupImageUrl,
  }) async {
    final cleanName = name.trim();
    final cleanDescription = description.trim();

    if (cleanName.isEmpty) {
      throw Exception('اسم المجموعة مطلوب');
    }

    final updates = <String, dynamic>{
      'name': cleanName,
      'groupName': cleanName,
      'description': cleanDescription,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (type != null) updates['type'] = type;
    if (groupImageUrl != null) updates['groupImageUrl'] = groupImageUrl;

    await _groups.doc(groupId).update(updates);
  }
}
