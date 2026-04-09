import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/notifications_service.dart';class LibraryFilesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://edu-mate12.firebasestorage.app',
  );

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  static Stream<QuerySnapshot<Map<String, dynamic>>> myUploadedFiles() {
    final user = currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('library_files')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> universityFiles() {
    return _firestore
        .collection('library_files')
        .where('visibility', isEqualTo: 'public')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateLibraryFile({
    required String fileId,
    required String subjectName,
    required String doctorName,
    required String description,
    required String college,
    required String specialization,
    required String level,
    required String term,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final docRef = _firestore.collection('library_files').doc(fileId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw Exception('الملف غير موجود');
    }

    if ((data['userId'] ?? '') != uid) {
      throw Exception('غير مصرح لك بتعديل هذا الملف');
    }

    await docRef.update({
      'subjectName': subjectName.trim(),
      'doctorName': doctorName.trim(),
      'description': description.trim(),
      'college': college,
      'specialization': specialization,
      'level': level,
      'term': term,
      'visibility': 'public',
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteLibraryFile({
    required String fileId,
    required String storagePath,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final docRef = _firestore.collection('library_files').doc(fileId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw Exception('الملف غير موجود');
    }

    if ((data['userId'] ?? '') != uid) {
      throw Exception('غير مصرح لك بحذف هذا الملف');
    }

    if (storagePath.trim().isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {}
    }

    await docRef.delete();
  }

  static Future<void> approveFile(String fileId) async {
    final docRef = _firestore.collection('library_files').doc(fileId);
    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw Exception('الملف غير موجود');
    }

    final fileOwnerId = (data['userId'] ?? '').toString();
    final fileTitle = (data['subjectName'] ?? data['title'] ?? 'ملف جديد').toString();

    await docRef.update({
      'visibility': 'public',
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (fileOwnerId.isNotEmpty) {
      await NotificationsService.createNotification(
        userId: fileOwnerId,
        title: 'تمت الموافقة على ملفك',
        body: 'تم قبول ملف $fileTitle وإتاحته داخل المكتبة.',
        type: 'library',
        senderId: currentUserId,
        fileId: fileId,
      );
    }
  }

  static Future<void> rejectFile(String fileId) async {
    await _firestore.collection('library_files').doc(fileId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}