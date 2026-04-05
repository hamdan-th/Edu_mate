import 'package:cloud_firestore/cloud_firestore.dart';

class FileModel {
  final String id;
  final String title;
  final String author;
  final String course;
  final String university;
  final String college;
  final String major;
  final String semester;
  final String fileType;
  final String thumbnailUrl;
  final String fileUrl;
  final String uploaderName;
  final String uploaderUsername;
  final String description;
  final DateTime? createdAt;
  final int likes;
  final int saves;
  final int downloads;
  final int views;
  final int shares;
  final String status;
  final String? userId;
  final String? storagePath;

  const FileModel({
    required this.id,
    required this.title,
    required this.author,
    required this.course,
    required this.university,
    required this.college,
    required this.major,
    required this.semester,
    required this.fileType,
    required this.thumbnailUrl,
    required this.fileUrl,
    required this.uploaderName,
    required this.uploaderUsername,
    required this.description,
    required this.createdAt,
    required this.likes,
    required this.saves,
    this.downloads = 0,
    this.views = 0,
    this.shares = 0,
    this.status = 'approved',
    this.userId,
    this.storagePath,
  });

  bool get isPdf =>
      fileType.toLowerCase() == 'pdf' ||
      fileUrl.toLowerCase().contains('.pdf');

  bool get isWord => fileType.toLowerCase() == 'word';

  String get displayUploader {
    if (uploaderUsername.trim().isNotEmpty) return '@$uploaderUsername';
    if (uploaderName.trim().isNotEmpty) return uploaderName;
    return 'غير معروف';
  }

  FileModel copyWith({
    int? likes,
    int? saves,
    int? downloads,
    int? views,
    int? shares,
    String? status,
  }) {
    return FileModel(
      id: id,
      title: title,
      author: author,
      course: course,
      university: university,
      college: college,
      major: major,
      semester: semester,
      fileType: fileType,
      thumbnailUrl: thumbnailUrl,
      fileUrl: fileUrl,
      uploaderName: uploaderName,
      uploaderUsername: uploaderUsername,
      description: description,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      saves: saves ?? this.saves,
      downloads: downloads ?? this.downloads,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      status: status ?? this.status,
      userId: userId,
      storagePath: storagePath,
    );
  }

  factory FileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    int readInt(String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FileModel(
      id: doc.id,
      title: (data['subjectName'] ?? '').toString(),
      author: (data['doctorName'] ?? '').toString(),
      course: (data['subjectName'] ?? '').toString(),
      university: (data['university'] ?? 'جامعة صنعاء').toString(),
      college: (data['college'] ?? '').toString(),
      major: (data['specialization'] ?? '').toString(),
      semester:
          '${data['level'] ?? ''}${data['term'] != null ? ' • ${data['term']}' : ''}',
      fileType: (data['fileType'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? '').toString(),
      fileUrl: (data['fileUrl'] ?? '').toString(),
      uploaderName: (data['uploaderName'] ?? '').toString(),
      uploaderUsername: (data['uploaderUsername'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      likes: readInt('likesCount'),
      saves: readInt('savesCount'),
      downloads: readInt('downloadsCount'),
      views: readInt('viewsCount'),
      shares: readInt('sharesCount'),
      status: (data['status'] ?? 'approved').toString(),
      userId: (data['userId'] ?? '').toString(),
      storagePath: (data['storagePath'] ?? '').toString(),
    );
  }
}
