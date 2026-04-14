import 'package:cloud_firestore/cloud_firestore.dart';

class RegistryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collectionName = 'university_registry';

  /// Looks up an identifier (academic or employee number) in the registry.
  /// Returns the document data if found, null otherwise.
  Future<Map<String, dynamic>?> lookup(String identifier) async {
    try {
      final doc = await _db.collection(collectionName).doc(identifier).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      // Log error or handle as needed
      print('Registry lookup error: $e');
    }
    return null;
  }
}
