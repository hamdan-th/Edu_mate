import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../services/notifications_service.dart';
import '../../services/upload_screening_service.dart';
class LibraryUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://edu-mate12.firebasestorage.app',
  );

  static Future<void> uploadLibraryFile({
    required File file,
    required String subjectName,
    required String doctorName,
    required String description,
    required String college,
    required String specialization,
    required String level,
    required String term,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final originalFileName = file.path.split('/').last;
      final extension = originalFileName.contains('.')
          ? originalFileName.split('.').last.toLowerCase()
          : 'file';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = '${timestamp}_${user.uid}.$extension';

      final ref = _storage
          .ref()
          .child('library_uploads')
          .child(user.uid)
          .child(safeName);

      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedBy': user.uid,
          'subjectName': subjectName.trim(),
          'doctorName': doctorName.trim(),
        },
      );

      // Perform pre-upload screening
      // Library allows both images and other files, we screen images specifically.
      await UploadScreeningService.validate(file, isImage: extension == 'jpg' || extension == 'jpeg' || extension == 'png');

      final snapshot = await ref.putFile(file, metadata);
      final fileUrl = await snapshot.ref.getDownloadURL();
      final fileLength = await file.length();
      final docRef = _firestore.collection('library_files').doc();

      await docRef.set({
        'id': docRef.id,
        'userId': user.uid,
        'uploaderName': userData['fullName'] ?? '',
        'uploaderUsername': userData['username'] ?? '',
        'uploaderPhotoUrl': userData['photoUrl'] ?? '',
        'subjectName': subjectName.trim(),
        'doctorName': doctorName.trim(),
        'description': description.trim(),
        'college': college,
        'specialization': specialization,
        'level': level,
        'term': term,
        'fileName': originalFileName,
        'fileSize': fileLength,
        'fileExtension': extension,
        'fileUrl': fileUrl,
        'thumbnailUrl': '',
        'storagePath': snapshot.ref.fullPath,
        'fileType': _mapFileType(extension),
        'likesCount': 0,
        'savesCount': 0,
        'downloadsCount': 0,
        'sharesCount': 0,
        'viewsCount': 0,
        'status': 'approved',
        'visibility': 'public',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await NotificationsService.createNotification(
        userId: user.uid,
        title: 'تم رفع ملفك بنجاح',
        body: 'أصبح ملف ${subjectName.trim()} متاحًا داخل المكتبة.',
        type: 'library',
        subType: 'library_file_uploaded',
        targetName: subjectName.trim(),
        senderId: user.uid,
        fileId: docRef.id,
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase upload error => plugin: ${e.plugin}');
      debugPrint('Firebase upload error => code: ${e.code}');
      debugPrint('Firebase upload error => message: ${e.message}');
      throw Exception('${e.plugin} | ${e.code} | ${e.message ?? 'Unknown error'}');
    } catch (e) {
      debugPrint('General upload error => $e');
      throw Exception(e.toString());
    }
  }

  static String _mapFileType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return 'Word';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'Image';
      default:
        return 'File';
    }
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}