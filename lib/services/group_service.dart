import 'dart:math';
import 'dart:async';
import 'notifications_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/group_membership_state.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'upload_screening_service.dart';

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

  /// Returns true if the currently-signed-in user has role == 'doctor'
  /// in their Firestore profile.  Conservative default: returns false on any
  /// read failure so that permission is never accidentally granted.
  static Future<bool> isCurrentUserDoctor() async {
    try {
      final ref = await _userRefByUid(currentUid);
      final snap = await ref.get();
      final data = snap.data() ?? {};
      final role = (data['role'] ?? '').toString().toLowerCase().trim();
      return role == 'doctor';
    } catch (_) {
      return false;
    }
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

  static Future<GroupMembershipState> getUserGroupState(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return GroupMembershipState.none();

    final groupDoc = await _groups.doc(groupId).get();
    if (!groupDoc.exists) return GroupMembershipState.none();

    final groupData = groupDoc.data() ?? {};
    final membersCanChat = (groupData['membersCanChat'] ?? true) == true;
    final banned = (groupData['bannedUserIds'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        <String>[];

    final isBanned = banned.contains(user.uid);

    final memberSnap =
    await _groups.doc(groupId).collection('members').doc(user.uid).get();

    if (!memberSnap.exists) {
      return GroupMembershipState(
        isMember: false,
        isOwner: false,
        isAdmin: false,
        isBanned: isBanned,
        isMuted: false,
        canSend: false,
        notificationsMuted: false,
        role: 'none',
      );
    }

    final data = memberSnap.data() ?? {};
    final role = data['role']?.toString() ?? 'member';
    final status = data['status']?.toString() ?? 'active';
    final groupOwnerId = (groupData['ownerId'] ?? '').toString();

    final isOwner = groupOwnerId == user.uid;
    final isAdmin = role == 'admin' || (role == 'owner' && !isOwner);
    final isMuted = status == 'muted';

    bool canSend = false;
    if (!isBanned && !isMuted) {
      if (isOwner || isAdmin) {
        canSend = true;
      } else if (membersCanChat) {
        canSend = true;
      }
    }

    return GroupMembershipState(
      isMember: true,
      isOwner: isOwner,
      isAdmin: isAdmin,
      isBanned: isBanned || status == 'banned',
      isMuted: isMuted,
      canSend: canSend,
      notificationsMuted: false,
      role: role,
    );
  }

  static Stream<List<GroupModel>> streamMyGroups() {
    final stream = Stream.fromFuture(_userRefByUid(currentUid)).asyncExpand(
          (userRef) {
        return userRef.collection('joined_groups').snapshots().asyncMap(
              (joinedSnap) async {
            final ids = joinedSnap.docs.map((e) => e.id).toSet();

            if (ids.isEmpty) return <GroupModel>[];

            final docs =
            await Future.wait(ids.map((id) => _groups.doc(id).get()));

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
              // Sort by latest activity (updatedAt) so recently active groups
              // rise to the top, falling back to createdAt for groups with
              // no messages yet.
              final aTime = (a.updatedAt ?? a.createdAt)?.millisecondsSinceEpoch ?? 0;
              final bTime = (b.updatedAt ?? b.createdAt)?.millisecondsSinceEpoch ?? 0;
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

    StreamController<List<GroupModel>>? controller;
    StreamSubscription? joinedSub;
    StreamSubscription? groupsSub;

    Set<String> joinedIds = {};
    List<DocumentSnapshot<Map<String, dynamic>>> groupDocs = [];

    void emitResults() {
      if (controller == null || controller.isClosed) return;

      final result = <GroupModel>[];
      for (final doc in groupDocs) {
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

      controller.add(result);
    }

    controller = StreamController<List<GroupModel>>.broadcast(
      onListen: () async {
        try {
          final userRef = await _userRefByUid(currentUid);

          joinedSub =
              userRef.collection('joined_groups').snapshots().listen((snap) {
                joinedIds = snap.docs.map((e) => e.id).toSet();
                emitResults();
              });

          groupsSub = _groups.snapshots().listen((snap) {
            groupDocs = snap.docs;
            emitResults();
          });
        } catch (_) {}
      },
      onCancel: () {
        joinedSub?.cancel();
        groupsSub?.cancel();
      },
    );

    return controller.stream;
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

    // Normalise the type string so dirty input (e.g. 'Public' / ' public ')
    // never bypasses the guard below.
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType != 'public' && normalizedType != 'private') {
      throw Exception('نوع المجموعة غير صالح');
    }

    // Business rule: only doctors may create public (global) groups.
    if (normalizedType == 'public') {
      final isDoctor = await isCurrentUserDoctor();
      if (!isDoctor) {
        throw Exception(
          'المجموعات العامة يمكن إنشاؤها من قِبَل الدكتور فقط. '
          'يُرجى اختيار نوع المجموعة الخاصة.',
        );
      }
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
      'type': normalizedType,
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
      'adminsCount': 0,
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
      'type': normalizedType,
    });

    await batch.commit();
    await NotificationsService.createNotification(
      userId: currentUid,
      title: 'تم إنشاء المجموعة بنجاح',
      body: 'تم إنشاء مجموعة $cleanName وأصبحت جاهزة الآن.',
      type: 'group',
      subType: 'group_created',
      targetName: cleanName,
      senderId: currentUid,
      groupId: groupRef.id,
    );
  }

  static Future<void> joinPublicGroup(String groupId) async {
    final state = await getUserGroupState(groupId);
    if (state.isBanned) {
      throw Exception('أنت محظور من هذه المجموعة');
    }
    if (state.isMember) return;

    final groupRef = _groups.doc(groupId);
    final userRef = await _userRefByUid(currentUid);
    final displayName = await _userDisplayName(currentUid);

    await _db.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }
      final joinedGroupSnap = await groupRef.get();
      final joinedGroupData = joinedGroupSnap.data() ?? {};
      final joinedGroupName =
      (joinedGroupData['name'] ?? joinedGroupData['groupName'] ?? '')
          .toString();

      await NotificationsService.createNotification(
        userId: currentUid,
        title: 'تم الانضمام إلى المجموعة',
        body: 'أصبحت الآن عضوًا في مجموعة $joinedGroupName',
        type: 'group',
        subType: 'group_joined',
        targetName: joinedGroupName,
        senderId: currentUid,
        groupId: groupId,
      );
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
        throw Exception('لا يمكنك الانضمام لهذه المجموعة مباشرة');
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
    final state = await getUserGroupState(group.id);
    if (state.isBanned) {
      throw Exception('أنت محظور من هذه المجموعة');
    }
    if (state.isMember) return;

    final groupRef = _groups.doc(group.id);
    final userRef = await _userRefByUid(currentUid);
    final displayName = await _userDisplayName(currentUid);

    await _db.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }
      await NotificationsService.createNotification(
        userId: currentUid,
        title: 'تم الانضمام إلى المجموعة الخاصة',
        body: 'أصبحت الآن عضوًا في مجموعة ${group.name}',
        type: 'group',
        subType: 'group_joined_private',
        targetName: group.name,
        senderId: currentUid,
        groupId: group.id,
      );
      final data = groupSnap.data() ?? {};

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

  static Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    final state = await getUserGroupState(groupId);
    if (!state.isMember) throw Exception('غير مصرح لك');
    
    final docRef = _groups.doc(groupId).collection('messages').doc(messageId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('الرسالة غير موجودة');
    final data = doc.data()!;
    if (data['senderId'] != currentUid) {
      throw Exception('لا يمكنك حذف رسالة شخص آخر');
    }

    await docRef.update({
      'text': '🚫 تم حذف هذه الرسالة',
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'type': 'text',
      'imageUrl': FieldValue.delete(),
    });
  }

  static Future<void> editMessage({
    required String groupId,
    required String messageId,
    required String newText,
  }) async {
    final cleanText = newText.trim();
    if (cleanText.isEmpty) throw Exception('لا يمكن أن تكون الرسالة فارغة');

    final state = await getUserGroupState(groupId);
    if (!state.isMember) throw Exception('غير مصرح لك');
    if (state.isBanned) throw Exception('أنت محظور من هذه المجموعة');
    if (state.isMuted) throw Exception('تم كتمك داخل هذه المجموعة');
    if (!state.canSend) throw Exception('المجموعة للقراءة فقط حاليًا');

    final docRef = _groups.doc(groupId).collection('messages').doc(messageId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('الرسالة غير موجودة');
    final data = doc.data()!;
    if (data['senderId'] != currentUid) {
      throw Exception('لا يمكنك تعديل رسالة شخص آخر');
    }
    if (data['isDeleted'] == true) {
      throw Exception('الرسالة محذوفة ولا يمكن تعديلها');
    }

    await docRef.update({
      'text': cleanText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendMessage({
    required String groupId,
    required String text,
    File? imageFile,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && imageFile == null) {
      throw Exception('لا يمكن إرسال رسالة فارغة');
    }

    final state = await getUserGroupState(groupId);
    if (!state.isMember) {
      throw Exception('يجب أن تكون عضوًا في المجموعة لإرسال رسالة');
    }
    if (state.isBanned) throw Exception('أنت محظور من هذه المجموعة');
    if (state.isMuted) throw Exception('تم كتمك داخل هذه المجموعة');
    if (!state.canSend) throw Exception('المجموعة للقراءة فقط حاليًا');

    final groupRef = _groups.doc(groupId);
    final displayName = await _userDisplayName(currentUid);

    String? imageUrl;
    if (imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('groups_chat')
          .child(groupId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$currentUid.jpg');
      
      // Perform pre-upload screening
      await UploadScreeningService.validate(imageFile, isImage: true);

      final uploadTask = await ref.putFile(imageFile);
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    final messageRef = groupRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(messageRef, {
      'messageId': messageRef.id,
      'senderId': currentUid,
      'senderName': displayName,
      'text': cleanText,
      'type': imageUrl != null ? 'image' : 'text',
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
    });

    batch.update(groupRef, {
      'messagesCount': FieldValue.increment(1),
      'lastMessageText': cleanText.isNotEmpty
          ? cleanText
          : (imageUrl != null ? '📷 Photo' : ''),
      'lastMessageType': imageUrl != null ? 'image' : 'text',
      'lastMessageSenderId': currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Marks all messages in [groupId] as read for the current user by
  /// stamping their membership doc with the current server time.
  static Future<void> markGroupAsRead(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _groups
          .doc(groupId)
          .collection('members')
          .doc(uid)
          .set({'lastReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns a live stream of the unread message count for the current user
  /// in [groupId].
  ///
  /// Design: avoids Firestore two-field inequality (which requires a composite
  /// index that may not exist). Instead:
  ///   - Queries messages ONLY by createdAt > lastReadAt  (single inequality –
  ///     no composite index needed beyond the default createdAt index).
  ///   - Filters out the current user's own messages client-side.
  ///
  /// Reacts to TWO triggers:
  ///   1. Member doc snapshot fires (lastReadAt changed → user opened chat).
  ///   2. Any new message arrives in the messages subcollection.
  static Stream<int> streamUnreadCount(String groupId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    final memberRef = _groups.doc(groupId).collection('members').doc(uid);
    final messagesRef = _groups.doc(groupId).collection('messages');

    final StreamController<int> controller = StreamController<int>.broadcast();
    StreamSubscription? memberSub;
    StreamSubscription? messagesSub;

    Timestamp? lastReadAt;
    bool ready = false;

    Future<void> recount() async {
      if (controller.isClosed) return;
      try {
        // Single-field inequality only → no composite index required.
        Query<Map<String, dynamic>> query = messagesRef;
        if (lastReadAt != null) {
          query = query.where('createdAt', isGreaterThan: lastReadAt);
        }
        final snap = await query.get();
        // Exclude own messages client-side.
        final count = snap.docs.where((d) {
          final sender = (d.data()['senderId'] ?? '').toString();
          return sender.isNotEmpty && sender != uid;
        }).length;
        if (!controller.isClosed) controller.add(count);
      } catch (e) {
        if (!controller.isClosed) controller.add(0);
      }
    }

    memberSub = memberRef.snapshots().listen((snap) {
      lastReadAt = (snap.data() ?? {})['lastReadAt'] as Timestamp?;
      ready = true;
      recount();
    }, onError: (_) {
      ready = true;
      recount();
    });

    // Listen for new messages — fires whenever a message is added or changed.
    messagesSub = messagesRef.snapshots().listen((_) {
      if (ready) recount();
    }, onError: (_) {});

    controller.onCancel = () {
      memberSub?.cancel();
      messagesSub?.cancel();
    };

    return controller.stream;
  }

  static Future<void> shareLibraryFileToGroup({
    required String groupId,
    required String fileId,
    required String fileTitle,
    required String fileUrl,
    String? fileType,
    String? note,
    String? ownerId,
    String? thumbnailUrl,
  }) async {
    final cleanNote = note?.trim() ?? '';
    final cleanTitle = fileTitle.trim();
    final cleanUrl = fileUrl.trim();
    final cleanType = fileType?.trim() ?? '';

    if (fileId.trim().isEmpty) {
      throw Exception('معرف الملف غير صالح');
    }

    if (cleanTitle.isEmpty) {
      throw Exception('عنوان الملف غير صالح');
    }

    if (cleanUrl.isEmpty) {
      throw Exception('رابط الملف غير صالح');
    }

    final state = await getUserGroupState(groupId);
    if (!state.isMember) {
      throw Exception('يجب أن تكون عضوًا في المجموعة للمشاركة');
    }
    if (state.isBanned) throw Exception('أنت محظور من هذه المجموعة');
    if (state.isMuted) throw Exception('تم كتمك داخل هذه المجموعة');
    if (!state.canSend) throw Exception('المجموعة للقراءة فقط حاليًا');

    final groupRef = _groups.doc(groupId);
    final displayName = await _userDisplayName(currentUid);
    final messageRef = groupRef.collection('messages').doc();

    final batch = _db.batch();

    batch.set(messageRef, {
      'messageId': messageRef.id,
      'senderId': currentUid,
      'senderName': displayName,
      'text': cleanNote,
      'type': 'library_file_link',
      'sharedFromLibrary': true,
      'sharedFileId': fileId.trim(),
      'sharedFileTitle': cleanTitle,
      'sharedFileUrl': cleanUrl,
      if (cleanType.isNotEmpty) 'sharedFileType': cleanType,
      if ((ownerId ?? '').trim().isNotEmpty) 'sharedFileOwnerId': ownerId!.trim(),
      if ((thumbnailUrl ?? '').trim().isNotEmpty)
        'sharedFileThumbnailUrl': thumbnailUrl!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(groupRef, {
      'messagesCount': FieldValue.increment(1),
      'lastMessageText': cleanTitle,
      'lastMessageType': 'library_file_link',
      'lastMessageSenderId': currentUid,
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
      rethrow;
    }
  }

  static Future<void> unsaveMessage({
    required String groupId,
    required String messageId,
  }) async {
    await _groups
        .doc(groupId)
        .collection('savedMessages')
        .doc(currentUid)
        .collection('items')
        .doc(messageId)
        .delete();
  }

  static Future<bool> isMessageSaved({
    required String groupId,
    required String messageId,
  }) async {
    try {
      final doc = await _groups
          .doc(groupId)
          .collection('savedMessages')
          .doc(currentUid)
          .collection('items')
          .doc(messageId)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamSavedMessages(String groupId) {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Stream.value([]);

      return _groups
          .doc(groupId)
          .collection('savedMessages')
          .doc(uid)
          .collection('items')
          .snapshots()
          .map((snap) {
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

  static Future<void> transferOwnership(String groupId, String newOwnerId) async {
    if (newOwnerId.trim().isEmpty) {
      throw Exception('المالك الجديد غير صالح');
    }

    final groupRef = _groups.doc(groupId);
    final newOwnerUserRef = await _userRefByUid(newOwnerId);

    final String groupName = await _db.runTransaction((tx) async {
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final groupData = groupSnap.data() ?? {};
      final currentOwnerId = (groupData['ownerId'] ?? '').toString();
      final gName = (groupData['name'] ?? groupData['groupName'] ?? '').toString();

      if (currentOwnerId != currentUid) {
        throw Exception('المالك الحالي فقط يمكنه نقل الملكية');
      }

      if (newOwnerId == currentOwnerId) {
        throw Exception('هذا العضو هو المالك بالفعل');
      }

      final newOwnerMemberRef = groupRef.collection('members').doc(newOwnerId);
      final newOwnerMemberSnap = await tx.get(newOwnerMemberRef);

      if (!newOwnerMemberSnap.exists) {
        throw Exception('العضو المحدد ليس عضوًا في المجموعة');
      }

      final duplicateOwnersSnap =
          await groupRef.collection('members').where('role', isEqualTo: 'owner').get();

      for (final memberDoc in duplicateOwnersSnap.docs) {
        tx.update(memberDoc.reference, {'role': 'admin'});
      }

      final oldOwnerMemberRef = groupRef.collection('members').doc(currentOwnerId);
      final oldOwnerMemberSnap = await tx.get(oldOwnerMemberRef);
      if (oldOwnerMemberSnap.exists) {
        tx.update(oldOwnerMemberRef, {'role': 'admin'});
      }

      tx.update(newOwnerMemberRef, {'role': 'owner'});

      tx.update(groupRef, {
        'ownerId': newOwnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final oldOwnerUserRef = await _userRefByUid(currentOwnerId);
      tx.set(
        oldOwnerUserRef.collection('joined_groups').doc(groupId),
        {
          'groupId': groupId,
          'groupName': gName,
          'roleInGroup': 'admin',
          'joinedAt': FieldValue.serverTimestamp(),
          'type': (groupData['type'] ?? 'public').toString(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        newOwnerUserRef.collection('joined_groups').doc(groupId),
        {
          'groupId': groupId,
          'groupName': gName,
          'roleInGroup': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
          'type': (groupData['type'] ?? 'public').toString(),
        },
        SetOptions(merge: true),
      );

      return gName;
    });

    await NotificationsService.createNotification(
      userId: newOwnerId,
      title: 'تم نقل ملكية المجموعة إليك',
      body: 'أصبحت الآن مالكًا لمجموعة جديدة',
      type: 'group',
      subType: 'group_ownership_transferred',
      targetName: groupName,
      senderId: currentUid,
      groupId: groupId,
    );
  }

  static Future<void> promoteToAdmin(String groupId, String memberId) async {
    final state = await getUserGroupState(groupId);
    // Only the group owner may promote members to admin.
    // Admins are explicitly excluded to satisfy business rules 2 and 4.
    if (!state.isOwner) {
      throw Exception('المالك فقط يمكنه ترقية الأعضاء إلى مشرفين');
    }

    final groupRef = _groups.doc(groupId);
    final groupDoc = await groupRef.get();
    final groupOwnerId = (groupDoc.data()?['ownerId'] ?? '').toString();

    if (memberId == groupOwnerId) {
      throw Exception('مالك المجموعة لا يمكن تغييره إلى مشرف');
    }

    final memberRef = groupRef.collection('members').doc(memberId);
    final memberDoc = await memberRef.get();

    if (memberDoc.exists) {
      final memberRole = (memberDoc.data()?['role'] ?? 'member').toString();
      if (memberRole == 'owner') {
        throw Exception('لا يمكن ترقية مالك المجموعة كمشرف');
      }

      await memberRef.update({'role': 'admin'});

      final promotedGroupSnap = await groupRef.get();
      final promotedGroupData = promotedGroupSnap.data() ?? {};
      final promotedGroupName =
      (promotedGroupData['name'] ?? promotedGroupData['groupName'] ?? '')
          .toString();

      final memberUserRef = await _userRefByUid(memberId);
      await memberUserRef.collection('joined_groups').doc(groupId).set({
        'roleInGroup': 'admin',
        'groupId': groupId,
        'groupName': promotedGroupName,
        'joinedAt': FieldValue.serverTimestamp(),
        'type': (promotedGroupData['type'] ?? 'public').toString(),
      }, SetOptions(merge: true));

      await NotificationsService.createNotification(
        userId: memberId,
        title: 'تمت ترقيتك إلى مشرف',
        body: 'أصبحت الآن مشرفًا في مجموعة $promotedGroupName',
        type: 'group',
        subType: 'group_promoted_admin',
        targetName: promotedGroupName,
        senderId: currentUid,
        groupId: groupId,
      );
    }
  }

  static Future<void> removeAdmin(String groupId, String memberId) async {
    final state = await getUserGroupState(groupId);
    if (!state.isOwner) throw Exception('المالك فقط يمكنه إزالة المشرفين');

    final groupRef = _groups.doc(groupId);
    final groupDoc = await groupRef.get();
    final groupOwnerId = (groupDoc.data()?['ownerId'] ?? '').toString();

    if (memberId == groupOwnerId) {
      throw Exception('لا يمكن إزالة صلاحيات مالك المجموعة');
    }

    final memberRef = groupRef.collection('members').doc(memberId);
    final memberDoc = await memberRef.get();

    if (memberDoc.exists) {
      final role = (memberDoc.data()?['role'] ?? 'member').toString();
      if (role == 'owner') {
        throw Exception('لا يمكن إزالة المالك من هنا، استخدم نقل الملكية');
      }

      await memberRef.update({'role': 'member'});

      final demotedGroupSnap = await groupRef.get();
      final demotedGroupData = demotedGroupSnap.data() ?? {};
      final demotedGroupName =
      (demotedGroupData['name'] ?? demotedGroupData['groupName'] ?? '')
          .toString();

      final memberUserRef = await _userRefByUid(memberId);
      await memberUserRef.collection('joined_groups').doc(groupId).set({
        'roleInGroup': 'member',
        'groupId': groupId,
        'groupName': demotedGroupName,
        'joinedAt': FieldValue.serverTimestamp(),
        'type': (demotedGroupData['type'] ?? 'public').toString(),
      }, SetOptions(merge: true));

      await NotificationsService.createNotification(
        userId: memberId,
        title: 'تمت إزالة صلاحية الإشراف',
        body: 'لم تعد مشرفًا في مجموعة $demotedGroupName',
        type: 'group',
        subType: 'group_demoted_admin',
        targetName: demotedGroupName,
        senderId: currentUid,
        groupId: groupId,
      );
    }
  }

  static Future<void> muteMember(String groupId, String memberId) async {
    final state = await getUserGroupState(groupId);
    if (!state.isOwner && !state.isAdmin) throw Exception('غير مصرح لك بهذا الإجراء');

    final groupRef = _groups.doc(groupId);
    final groupDoc = await groupRef.get();
    final groupOwnerId = (groupDoc.data()?['ownerId'] ?? '').toString();

    if (memberId == groupOwnerId) {
      throw Exception('لا يمكن كتم مالك المجموعة');
    }

    final memberRef = groupRef.collection('members').doc(memberId);
    final memberDoc = await memberRef.get();

    if (memberDoc.exists && memberDoc.data()?['role'] != 'owner') {
      await memberRef.update({'status': 'muted'});

      final mutedGroupSnap = await groupRef.get();
      final mutedGroupData = mutedGroupSnap.data() ?? {};
      final mutedGroupName =
      (mutedGroupData['name'] ?? mutedGroupData['groupName'] ?? '').toString();

      await NotificationsService.createNotification(
        userId: memberId,
        title: 'تم كتمك داخل المجموعة',
        body: 'لم يعد بإمكانك إرسال الرسائل في مجموعة $mutedGroupName',
        type: 'group',
        subType: 'group_muted',
        targetName: mutedGroupName,
        senderId: currentUid,
        groupId: groupId,
      );
    }
  }

  static Future<void> unmuteMember(String groupId, String memberId) async {
    final state = await getUserGroupState(groupId);
    if (!state.isOwner && !state.isAdmin) throw Exception('غير مصرح لك بهذا الإجراء');

    final memberRef = _groups.doc(groupId).collection('members').doc(memberId);
    final memberDoc = await memberRef.get();

    if (memberDoc.exists) {
      await memberRef.update({'status': 'active'});

      final unmutedGroupSnap = await _groups.doc(groupId).get();
      final unmutedGroupData = unmutedGroupSnap.data() ?? {};
      final unmutedGroupName =
      (unmutedGroupData['name'] ?? unmutedGroupData['groupName'] ?? '').toString();

      await NotificationsService.createNotification(
        userId: memberId,
        title: 'تم فك الكتم عنك',
        body: 'يمكنك الآن إرسال الرسائل من جديد في مجموعة $unmutedGroupName',
        type: 'group',
        subType: 'group_unmuted',
        targetName: unmutedGroupName,
        senderId: currentUid,
        groupId: groupId,
      );
    }
  }

  static Future<void> kickMember(String groupId, String memberId) async {
    final state = await getUserGroupState(groupId);
    if (!state.isOwner && !state.isAdmin) throw Exception('غير مصرح لك بهذا الإجراء');

    final groupRef = _groups.doc(groupId);
    final memberRef = groupRef.collection('members').doc(memberId);
    final memberDoc = await memberRef.get();

    if (!memberDoc.exists) return;

    final groupData = (await groupRef.get()).data() ?? {};
    final groupOwnerId = (groupData['ownerId'] ?? '').toString();

    if (memberId == groupOwnerId || memberDoc.data()?['role'] == 'owner') {
      throw Exception("لا يمكن طرد مالك المجموعة");
    }

    final kickedGroupName =
    (groupData['name'] ?? groupData['groupName'] ?? '').toString();

    final memberUserRef = await _userRefByUid(memberId);

    final batch = _db.batch();
    batch.delete(memberRef);
    batch.delete(memberUserRef.collection('joined_groups').doc(groupId));
    batch.update(groupRef, {
      'membersCounts': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    await NotificationsService.createNotification(
      userId: memberId,
      title: 'تمت إزالتك من المجموعة',
      body: 'تمت إزالة عضويتك من مجموعة $kickedGroupName',
      type: 'group',
      subType: 'group_kicked',
      targetName: kickedGroupName,
      senderId: currentUid,
      groupId: groupId,
    );
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
    final state = await getUserGroupState(group.id);
    if (group.type != 'public') {
      throw Exception('النشر المتزامن متاح فقط للمجموعات العامة');
    }
    if (!state.isOwner && !state.isAdmin) {
      throw Exception('المالك والمشرف فقط يمكنهم النشر في الفيد العام');
    }

    final cleanText = text.trim();
    if (cleanText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      throw Exception('لا يمكن نشر محتوى فارغ');
    }

    final displayName = await _userDisplayName(currentUid);
    final batch = _db.batch();

    final postRef = _db.collection('posts').doc();

    batch.set(postRef, {
      'postId': postRef.id,
      'groupId': group.id,
      'groupName': group.name,
      'groupImageUrl': group.imageUrl,
      'authorId': currentUid,
      'authorName': displayName,
      'contentText': cleanText,
      if (imageUrl != null && imageUrl.isNotEmpty) 'contentImageUrl': imageUrl,
      'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'group_public',
      'likesCount': 0,
      'commentsCount': 0,
    });

    await batch.commit();
  }

  static Future<void> clearGroupChat(String groupId) async {
    final state = await getUserGroupState(groupId);
    if (!state.isOwner && !state.isAdmin) {
      throw Exception('غير مصرح لك بهذا الإجراء');
    }

    final messagesQuery = _groups.doc(groupId).collection('messages');

    while (true) {
      final snapshot = await messagesQuery.limit(500).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      final groupRef = _groups.doc(groupId);
      batch.update(groupRef, {
        'messagesCount': FieldValue.increment(-snapshot.docs.length),
        'lastMessageText': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }

  /// Toggle a reaction emoji on a message.
  ///
  /// Rules (one reaction per user per message):
  /// * Same emoji tapped again → delete the doc (toggle off).
  /// * Different emoji → overwrite (replaces old reaction).
  /// * No previous reaction → create the doc.
  static Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String emoji,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _groups
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .collection('reactions')
        .doc(uid);

    final snap = await ref.get();
    if (snap.exists && snap.data()?['emoji'] == emoji) {
      // Same emoji → toggle off.
      await ref.delete();
    } else {
      // New or different emoji → set/overwrite.
      await ref.set({
        'uid': uid,
        'emoji': emoji,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  // ── Pinned Messages ────────────────────────────────────────────────

  /// Pins a message at the group level.
  /// Stored in `groups/{groupId}/pinnedMessages/{messageId}`.
  static Future<void> pinMessage({
    required String groupId,
    required String messageId,
    required Map<String, dynamic> data,
    required String pinnedByName,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final type = (data['type'] ?? 'text').toString();
    final text = (data['text'] ?? '').toString().trim();
    String previewText;
    if (text.isNotEmpty) {
      previewText = text.length > 120 ? '${text.substring(0, 120)}…' : text;
    } else if (type == 'image') {
      previewText = '📷 Photo';
    } else if (type == 'library_file_link') {
      previewText =
          (data['sharedFileTitle'] ?? '📎 File').toString();
    } else {
      previewText = '…';
    }

    await _groups
        .doc(groupId)
        .collection('pinnedMessages')
        .doc(messageId)
        .set({
      'messageId': messageId,
      'pinnedBy': uid,
      'pinnedByName': pinnedByName,
      'pinnedAt': Timestamp.now(),
      'messageType': type,
      'previewText': previewText,
      'senderName': (data['senderName'] ?? '').toString(),
    });
  }

  /// Removes a pinned message.
  static Future<void> unpinMessage({
    required String groupId,
    required String messageId,
  }) async {
    await _groups
        .doc(groupId)
        .collection('pinnedMessages')
        .doc(messageId)
        .delete();
  }

  /// One-shot check: is this message currently pinned?
  static Future<bool> isPinned({
    required String groupId,
    required String messageId,
  }) async {
    final snap = await _groups
        .doc(groupId)
        .collection('pinnedMessages')
        .doc(messageId)
        .get();
    return snap.exists;
  }

  /// Streams the most recently pinned message for the group banner.
  static Stream<DocumentSnapshot<Map<String, dynamic>>?> streamLatestPin(
      String groupId) {
    return _groups
        .doc(groupId)
        .collection('pinnedMessages')
        .orderBy('pinnedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : snap.docs.first);
  }

  /// Streams ALL pinned messages ordered by pinnedAt DESC — for the pinned
  /// history sheet.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamAllPins(
      String groupId) {
    return _groups
        .doc(groupId)
        .collection('pinnedMessages')
        .orderBy('pinnedAt', descending: true)
        .snapshots();
  }

  /// Fetches a single group by its ID.
  static Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _groups.doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (_) {
      return null;
    }
  }
}
