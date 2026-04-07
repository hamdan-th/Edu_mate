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

  FileModel({
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

  bool get isPdf => fileType.toLowerCase() == 'pdf' || fileUrl.toLowerCase().contains('.pdf');

  bool get isWord => fileType.toLowerCase() == 'word';

  String get displayUploader {
    if (uploaderUsername.trim().isNotEmpty) return '@$uploaderUsername';
    if (uploaderName.trim().isNotEmpty) return uploaderName;
    return 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ';
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

  factory FileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    int readInt(String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${data[key] ?? 0}') ?? 0;
    }

    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
    final subjectName = (data['subjectName'] ?? data['title'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†').toString();
    final doctorName = (data['doctorName'] ?? data['author'] ?? 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ').toString();
    final college = (data['college'] ?? '').toString();
    final specialization = (data['specialization'] ?? data['major'] ?? '').toString();
    final level = (data['level'] ?? '').toString();
    final term = (data['term'] ?? '').toString();

    return FileModel(
      id: doc.id,
      title: subjectName,
      author: doctorName,
      course: subjectName,
      university: (data['university'] ?? 'ط¬ط§ظ…ط¹ط© طµظ†ط¹ط§ط،').toString(),
      college: college,
      major: specialization,
      semester: '$level${term.isNotEmpty ? ' â€¢ $term' : ''}',
      fileType: (data['fileType'] ?? 'File').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? '').toString(),
      fileUrl: (data['fileUrl'] ?? '').toString(),
      uploaderName: (data['uploaderName'] ?? '').toString(),
      uploaderUsername: (data['uploaderUsername'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      createdAt: createdAtTimestamp?.toDate(),
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

