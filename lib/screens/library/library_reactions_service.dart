import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryReactionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Stream<bool> isLikedStream(String fileId) {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('library_files')
        .doc(fileId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Stream<bool> isSavedStream(String fileId) {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('library_files')
        .doc(fileId)
        .collection('saves')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Future<void> toggleLike({
    required String fileId,
    required bool isCurrentlyLiked,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final fileRef = _firestore.collection('library_files').doc(fileId);
    final likeRef = fileRef.collection('likes').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final fileSnap = await transaction.get(fileRef);
      final currentLikes =
          ((fileSnap.data()?['likesCount'] ?? 0) as num).toInt();

      if (isCurrentlyLiked) {
        transaction.delete(likeRef);
        transaction.update(fileRef, {
          'likesCount': currentLikes > 0 ? currentLikes - 1 : 0,
        });
      } else {
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(fileRef, {
          'likesCount': currentLikes + 1,
        });
      }
    });
  }

  static Future<void> toggleSave({
    required String fileId,
    required bool isCurrentlySaved,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final fileRef = _firestore.collection('library_files').doc(fileId);
    final saveRef = fileRef.collection('saves').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final fileSnap = await transaction.get(fileRef);
      final currentSaves =
          ((fileSnap.data()?['savesCount'] ?? 0) as num).toInt();

      if (isCurrentlySaved) {
        transaction.delete(saveRef);
        transaction.update(fileRef, {
          'savesCount': currentSaves > 0 ? currentSaves - 1 : 0,
        });
      } else {
        transaction.set(saveRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(fileRef, {
          'savesCount': currentSaves + 1,
        });
      }
    });
  }

  static Future<void> registerDownload(String fileId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final fileRef = _firestore.collection('library_files').doc(fileId);
    final downloadRef = fileRef.collection('downloads').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final fileSnap = await transaction.get(fileRef);
      final currentDownloads =
          ((fileSnap.data()?['downloadsCount'] ?? 0) as num).toInt();
      final alreadyDownloaded = (await downloadRef.get()).exists;

      if (!alreadyDownloaded) {
        transaction.set(downloadRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(fileRef, {
          'downloadsCount': currentDownloads + 1,
        });
      }
    });
  }

  static Future<void> registerShare(String fileId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final fileRef = _firestore.collection('library_files').doc(fileId);
    final shareRef = fileRef.collection('shares').doc();

    await _firestore.runTransaction((transaction) async {
      final fileSnap = await transaction.get(fileRef);
      final currentShares =
          ((fileSnap.data()?['sharesCount'] ?? 0) as num).toInt();

      transaction.set(shareRef, {
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(fileRef, {
        'sharesCount': currentShares + 1,
      });
    });
  }

  static Future<void> registerViewOnce(String fileId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final fileRef = _firestore.collection('library_files').doc(fileId);
    final viewRef = fileRef.collection('views').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final alreadyViewed = (await viewRef.get()).exists;
      if (alreadyViewed) return;

      final fileSnap = await transaction.get(fileRef);
      final currentViews =
          ((fileSnap.data()?['viewsCount'] ?? 0) as num).toInt();

      transaction.set(viewRef, {
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(fileRef, {
        'viewsCount': currentViews + 1,
      });
    });
  }
}
