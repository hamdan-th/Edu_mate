import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LibraryLocalDownloadService {
  static final Dio _dio = Dio();
  static Box get _box => Hive.box('downloads_box');

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

    await _box.put(fileId, {
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
    return _box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort(
            (a, b) => (b['downloadedAt'] ?? '')
            .toString()
            .compareTo((a['downloadedAt'] ?? '').toString()),
      );
  }

  static Future<void> removeDownloadedFile(String fileId) async {
    final item = _box.get(fileId);
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
    await _box.delete(fileId);
  }

  static bool isDownloaded(String fileId) {
    return _box.containsKey(fileId);
  }

  static String? getLocalPath(String fileId) {
    final item = _box.get(fileId);
    if (item == null) return null;
    final map = Map<String, dynamic>.from(item as Map);
    return map['localPath']?.toString();
  }
}