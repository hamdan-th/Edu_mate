import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class ScreeningException implements Exception {
  final String message;
  ScreeningException(this.message);
  @override
  String toString() => message;
}

class UploadScreeningService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Academic whitelist
  static const List<String> _allowedExtensions = [
    'pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'
  ];

  // Dangerous blacklist
  static const List<String> _blockedExtensions = [
    'exe', 'apk', 'bat', 'cmd', 'js', 'jar', 'sh', 'ps1'
  ];

  /// Core validation orchestrator
  static Future<void> validate(File file, {bool isImage = false}) async {
    final fileName = file.path.split('/').last.toLowerCase();
    final extension = fileName.contains('.') ? fileName.split('.').last : '';

    // 1. Extension Check
    if (_blockedExtensions.contains(extension)) {
      throw ScreeningException('عذراً، لا يمكن رفع ملفات من هذا النوع لأسباب أمنية ($extension)');
    }
    
    if (!_allowedExtensions.contains(extension)) {
      throw ScreeningException('نوع الملف غير مدعوم. يرجى رفع ملفات أكاديمية فقط (PDF, Word, PPT, Image)');
    }

    // 2. File Size Check (Configurable via Firestore)
    await _checkFileSize(file);

    // 3. Image Content Screening (Remote)
    if (isImage) {
      await _screenImageContent(file);
    }
  }

  static Future<void> _checkFileSize(File file) async {
    try {
      final configDoc = await _firestore.collection('app_config').doc('upload_settings').get();
      
      // Default to 20MB if not configured
      int maxSizeBytes = 20 * 1024 * 1024; 
      
      if (configDoc.exists) {
        final data = configDoc.data();
        if (data != null && data['maxFileSizeMB'] != null) {
          maxSizeBytes = (data['maxFileSizeMB'] as int) * 1024 * 1024;
        }
      }

      final fileLength = await file.length();
      if (fileLength > maxSizeBytes) {
        final mbLimit = maxSizeBytes / (1024 * 1024);
        throw ScreeningException('حجم الملف كبير جداً. الحد الأقصى المسموح به هو ${mbLimit.toStringAsFixed(0)} ميجابايت.');
      }
    } catch (e) {
      if (e is ScreeningException) rethrow;
      // If config fails, we fall back to a safe 10MB default
      final fileLength = await file.length();
      if (fileLength > 10 * 1024 * 1024) {
        throw ScreeningException('حجم الملف يتجاوز الحد المسموح به حالياً.');
      }
    }
  }

  static Future<void> _screenImageContent(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _functions.httpsCallable('screenContent').call({
        'image': base64Image,
      });

      final data = result.data;
      if (data['status'] == 'reject') {
        throw ScreeningException(data['reason'] ?? 'تم رفض الصورة لاحتوائها على محتوى غير لائق.');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Screening Function Error: ${e.code} | ${e.message}');
      // On technical failure, we let it pass but log it.
      // In a very strict environment, you might block here.
    } catch (e) {
      if (e is ScreeningException) rethrow;
      debugPrint('General Screening Error: $e');
    }
  }

  /// Helper to show the error dialog
  static void showScanError(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('فحص المحتوى', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          error.toString().replaceAll('Exception: ', ''),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
