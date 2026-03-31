// lib/file_model.dart

class FileModel {
  final String id;
  final String title; // <-- رجعت هنا
  final String author; // <-- رجعت هنا
  final String course;
  final String university;
  final String college;
  final String major;
  final String semester;
  final String fileType;
  final String thumbnailUrl;
  final String fileUrl;
  final int likes;
  final int saves;

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
    required this.likes,
    required this.saves,
  });
}

// قائمة البيانات الوهمية (تم تحديثها)
final List<FileModel> dummyFiles = [
FileModel(
id: '1',
title: 'محاضرات التفاضل والتكامل 1',
author: 'د. أحمد المصري',
course: 'التفاضل والتكامل 1',
university: 'جامعة الملك سعود',
college: 'كلية العلوم',
major: 'الرياضيات',
semester: 'الفصل الأول 2023',
fileType: 'PDF',
thumbnailUrl: 'https://i.imgur.com/2c0a1x4.png', // صورة غلاف كتاب رياضيات
fileUrl: 'url_to_file_1',
likes: 150,
saves: 75,
),
FileModel(
id: '2',
title: 'مقدمة في هياكل البيانات',
author: 'د. سارة الجهني',
course: 'هياكل البيانات',
university: 'جامعة الملك عبد العزيز',
college: 'كلية الهندسة وتقنية المعلومات',
major: 'هندسة الحاسب',
semester: 'الفصل الثاني 2023',
fileType: 'PDF',
thumbnailUrl: 'https://i.imgur.com/O3y5g3A.png', // صورة غلاف كتاب برمجة
fileUrl: 'url_to_file_2',
likes: 230,
saves: 120,
),
// ابحث عن هذا العنصر واستبدله بالكامل
FileModel(
id: '3',
title: 'ملخص قوانين الفيزياء العامة',
author: 'م. خالد الغامدي',
course: 'الفيزياء العامة',
university: 'جامعة الملك فهد للبترول والمعادن',
college: 'كلية العلوم الهندسية',
major: 'الهندسة الميكانيكية',
semester: 'الفصل الأول 2023',
fileType: 'Word',
thumbnailUrl: 'https://i.imgur.com/sT4bYfU.png',
// --- هذه هي الأسطر المضافة ---
fileUrl: 'url_to_file_3',
likes: 95,
saves: 40,

),
];
