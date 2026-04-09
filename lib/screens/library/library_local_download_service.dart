import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LibraryLocalDownloadService {
  static final Dio _dio = Dio();
  static const String _boxName = 'downloads_box';

  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  static Future<String> _downloadsFolderPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/library_downloads');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path;
  }

  static String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static Future<void> downloadAndSaveFile({
    required String fileId,
    required String title,
    required String fileUrl,
    required String fileType,
    required String course,
    required String author,
  }) async {
    final box = await _getBox();
    final folderPath = await _downloadsFolderPath();

    String extension = fileType.toLowerCase().trim();
    if (extension == 'pdf') {
      extension = 'pdf';
    } else if (extension == 'word') {
      extension = 'docx';
    } else if (extension == 'image') {
      extension = 'jpg';
    } else {
      extension = 'file';
    }

    final fileName = '${_safeFileName(title)}.$extension';
    final savePath = '$folderPath/$fileName';

    await _dio.download(fileUrl, savePath);

    await box.put(fileId, {
      'fileId': fileId,
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'course': course,
      'author': author,
      'localPath': savePath,
      'downloadedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getDownloadedFiles() async {
    final box = await _getBox();

    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort(
            (a, b) => (b['downloadedAt'] ?? '')
            .toString()
            .compareTo((a['downloadedAt'] ?? '').toString()),
      );
  }

  static Future<void> removeDownloadedFile(String fileId) async {
    final box = await _getBox();

    final item = box.get(fileId);
    if (item != null) {
      final map = Map<String, dynamic>.from(item as Map);
      final localPath = map['localPath']?.toString();
      if (localPath != null && localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await box.delete(fileId);
  }

  static Future<bool> isDownloaded(String fileId) async {
    final box = await _getBox();
    return box.containsKey(fileId);
  }

  static Future<String?> getLocalPath(String fileId) async {
    final box = await _getBox();

    final item = box.get(fileId);
    if (item == null) return null;
    final map = Map<String, dynamic>.from(item as Map);
    return map['localPath']?.toString();
  }
}