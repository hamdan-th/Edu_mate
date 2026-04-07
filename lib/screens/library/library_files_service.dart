import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LibraryFilesService {
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
    if (uid == null) throw Exception('ظٹط¬ط¨ طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„ ط£ظˆظ„ط§ظ‹');

    final docRef = _firestore.collection('library_files').doc(fileId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw Exception('ط§ظ„ظ…ظ„ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯');
    }

    if ((data['userId'] ?? '') != uid) {
      throw Exception('ط؛ظٹط± ظ…طµط±ط­ ظ„ظƒ ط¨طھط¹ط¯ظٹظ„ ظ‡ط°ط§ ط§ظ„ظ…ظ„ظپ');
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
    if (uid == null) throw Exception('ظٹط¬ط¨ طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„ ط£ظˆظ„ط§ظ‹');

    final docRef = _firestore.collection('library_files').doc(fileId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw Exception('ط§ظ„ظ…ظ„ظپ ط؛ظٹط± ظ…ظˆط¬ظˆط¯');
    }

    if ((data['userId'] ?? '') != uid) {
      throw Exception('ط؛ظٹط± ظ…طµط±ط­ ظ„ظƒ ط¨ط­ط°ظپ ظ‡ط°ط§ ط§ظ„ظ…ظ„ظپ');
    }

    if (storagePath.trim().isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {}
    }

    await docRef.delete();
  }

  static Future<void> approveFile(String fileId) async {
    await _firestore.collection('library_files').doc(fileId).update({
      'visibility': 'public',
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rejectFile(String fileId) async {
    await _firestore.collection('library_files').doc(fileId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
