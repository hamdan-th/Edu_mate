import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DigitalLibraryFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<void> saveReference(Map<String, dynamic> result) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final articleId = (result['id'] ?? '').toString();
    if (articleId.isEmpty) throw Exception('معرف الورقة غير موجود');

    final authors = (result['authors'] as List<dynamic>?)
            ?.map((author) => author['name'].toString())
            .join(', ') ??
        '';

    final journal = result['journals'] is List &&
            (result['journals'] as List).isNotEmpty
        ? (result['journals'] as List).first.toString()
        : '';

    final sourceUrl = 'https://core.ac.uk/display/$articleId';

    await _firestore
        .collection('digital_saved_references')
        .doc('${uid}_$articleId')
        .set({
      'userId': uid,
      'articleId': articleId,
      'title': (result['title'] ?? '').toString(),
      'authors': authors,
      'abstract': (result['abstract'] ?? '').toString(),
      'publisher': (result['publisher'] ?? '').toString(),
      'yearPublished': (result['yearPublished'] ?? '').toString(),
      'journal': journal,
      'downloadUrl': (result['downloadUrl'] ?? '').toString(),
      'sourceUrl': sourceUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> registerDownload(Map<String, dynamic> result) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final articleId = (result['id'] ?? '').toString();
    if (articleId.isEmpty) throw Exception('معرف الورقة غير موجود');

    final authors = (result['authors'] as List<dynamic>?)
            ?.map((author) => author['name'].toString())
            .join(', ') ??
        '';

    final journal = result['journals'] is List &&
            (result['journals'] as List).isNotEmpty
        ? (result['journals'] as List).first.toString()
        : '';

    final sourceUrl = 'https://core.ac.uk/display/$articleId';

    await _firestore
        .collection('digital_downloads')
        .doc('${uid}_$articleId')
        .set({
      'userId': uid,
      'articleId': articleId,
      'title': (result['title'] ?? '').toString(),
      'authors': authors,
      'abstract': (result['abstract'] ?? '').toString(),
      'publisher': (result['publisher'] ?? '').toString(),
      'yearPublished': (result['yearPublished'] ?? '').toString(),
      'journal': journal,
      'downloadUrl': (result['downloadUrl'] ?? '').toString(),
      'sourceUrl': sourceUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> registerShare(Map<String, dynamic> result) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final articleId = (result['id'] ?? '').toString();
    if (articleId.isEmpty) throw Exception('معرف الورقة غير موجود');

    final authors = (result['authors'] as List<dynamic>?)
            ?.map((author) => author['name'].toString())
            .join(', ') ??
        '';

    final journal = result['journals'] is List &&
            (result['journals'] as List).isNotEmpty
        ? (result['journals'] as List).first.toString()
        : '';

    final sourceUrl = 'https://core.ac.uk/display/$articleId';

    await _firestore.collection('digital_shares').add({
      'userId': uid,
      'articleId': articleId,
      'title': (result['title'] ?? '').toString(),
      'authors': authors,
      'abstract': (result['abstract'] ?? '').toString(),
      'publisher': (result['publisher'] ?? '').toString(),
      'yearPublished': (result['yearPublished'] ?? '').toString(),
      'journal': journal,
      'downloadUrl': (result['downloadUrl'] ?? '').toString(),
      'sourceUrl': sourceUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
