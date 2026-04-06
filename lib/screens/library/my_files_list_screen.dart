import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core_result_details_screen.dart';
import 'digital_library_firestore_service.dart';
import 'file_details_screen.dart';
import 'file_model.dart';
import 'library_files_service.dart';
import 'library_theme.dart';
import 'pdf_preview_screen.dart';

class MyFilesListScreen extends StatelessWidget {
  final String title;
  const MyFilesListScreen({Key? key, required this.title}) : super(key: key);

  FileModel _mapDocToFileModel(Map<String, dynamic> data, String docId) {
    final subjectName = (data['subjectName'] ?? 'بدون عنوان').toString();
    final doctorName = (data['doctorName'] ?? 'غير معروف').toString();
    final college = (data['college'] ?? '').toString();
    final specialization = (data['specialization'] ?? '').toString();
    final level = (data['level'] ?? '').toString();
    final term = (data['term'] ?? '').toString();
    final fileType = (data['fileType'] ?? 'File').toString();
    final fileUrl = (data['fileUrl'] ?? '').toString();
    final thumbnailUrl = (data['thumbnailUrl'] ?? '').toString();
    final uploaderName = (data['uploaderName'] ?? '').toString();
    final uploaderUsername = (data['uploaderUsername'] ?? '').toString();
    final description = (data['description'] ?? '').toString();

    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
    final DateTime? createdAt = createdAtTimestamp?.toDate();

    final likesCount = (data['likesCount'] ?? 0) is int
        ? (data['likesCount'] ?? 0) as int
        : int.tryParse('${data['likesCount']}') ?? 0;

    final savesCount = (data['savesCount'] ?? 0) is int
        ? (data['savesCount'] ?? 0) as int
        : int.tryParse('${data['savesCount']}') ?? 0;

    return FileModel(
      id: docId,
      title: subjectName,
      author: doctorName,
      course: subjectName,
      university: 'جامعة صنعاء',
      college: college,
      major: specialization,
      semester: '$level${term.isNotEmpty ? ' • $term' : ''}',
      fileType: fileType,
      thumbnailUrl: thumbnailUrl,
      fileUrl: fileUrl,
      uploaderName: uploaderName,
      uploaderUsername: uploaderUsername,
      description: description,
      createdAt: createdAt,
      likes: likesCount,
      saves: savesCount,
      downloads: ((data['downloadsCount'] ?? 0) is int ? (data['downloadsCount'] ?? 0) as int : int.tryParse('${data['downloadsCount']}') ?? 0),
      views: ((data['viewsCount'] ?? 0) is int ? (data['viewsCount'] ?? 0) as int : int.tryParse('${data['viewsCount']}') ?? 0),
      shares: ((data['sharesCount'] ?? 0) is int ? (data['sharesCount'] ?? 0) as int : int.tryParse('${data['sharesCount']}') ?? 0),
      status: (data['status'] ?? 'approved').toString(),
      userId: (data['userId'] ?? '').toString(),
      storagePath: (data['storagePath'] ?? '').toString(),
    );
  }

  Map<String, dynamic> _mapDigitalDocToCoreResult(Map<String, dynamic> data) {
    final authorsString = (data['authors'] ?? '').toString();

    final authorsList = authorsString.isEmpty
        ? <Map<String, dynamic>>[]
        : authorsString
            .split(',')
            .map((name) => {'name': name.trim()})
            .toList();

    return {
      'id': data['articleId'],
      'title': data['title'],
      'authors': authorsList,
      'abstract': data['abstract'],
      'publisher': data['publisher'],
      'yearPublished': data['yearPublished'],
      'journals': data['journal'] == null ||
              (data['journal'] ?? '').toString().isEmpty
          ? <String>[]
          : [data['journal'].toString()],
      'downloadUrl': data['downloadUrl'],
    };
  }

  Future<void> _openDownloadedFile(BuildContext context, FileModel file) async {
    final url = file.fileUrl.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رابط للملف')),
      );
      return;
    }

    final isPdf =
        file.fileType.toLowerCase() == 'pdf' || url.toLowerCase().contains('.pdf');

    if (isPdf) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            url: url,
            title: file.title,
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الملف')),
      );
    }
  }

  Widget _buildFileList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    String emptyMessage = 'لا توجد ملفات';
    if (title == 'المراجع') emptyMessage = 'لم تقم بحفظ أي ملفات بعد';
    if (title == 'ما رفعته') emptyMessage = 'لم تقم برفع أي ملفات بعد';
    if (title == 'تنزيلاتي') emptyMessage = 'لم تقم بتنزيل أي ملفات بعد';
    if (title == 'ما شاركته') emptyMessage = 'لم تقم بمشاركة أي ملفات بعد';

    if (docs.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final fileType = (data['fileType'] ?? '').toString().toLowerCase();
        final isPdf = fileType == 'pdf';
        final file = _mapDocToFileModel(data, docs[index].id);

        return GestureDetector(
          onTap: () {
            if (title == 'تنزيلاتي') {
              _openDownloadedFile(context, file);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileDetailsScreen(file: file),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (isPdf ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor)
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.description_rounded,
                  color: isPdf ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
                ),
              ),
              title: Text(
                data['subjectName'] ?? 'بدون عنوان',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${data['doctorName'] ?? ''} • ${data['college'] ?? ''}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (data['fileType'] ?? '').toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (data['status'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDigitalReferenceList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مراجع رقمية محفوظة',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final mapped = _mapDigitalDocToCoreResult(data);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CoreResultDetailsScreen(
                  resultData: mapped,
                  isSaved: true,
                  onToggleSave: () {},
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              title: Text(
                data['title'] ?? 'بدون عنوان',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${data['authors'] ?? ''} • ${data['yearPublished'] ?? ''}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    switch (title) {
      case 'ما رفعته':
        return FirebaseFirestore.instance
            .collection('library_files')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots();

      case 'ما شاركته':
        return FirebaseFirestore.instance
            .collectionGroup('shares')
            .where('userId', isEqualTo: user.uid)
            .snapshots();

      case 'تنزيلاتي':
        return FirebaseFirestore.instance
            .collectionGroup('downloads')
            .where('userId', isEqualTo: user.uid)
            .snapshots();

      case 'المراجع':
        return FirebaseFirestore.instance
            .collectionGroup('saves')
            .where('userId', isEqualTo: user.uid)
            .snapshots();

      default:
        return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: user == null
          ? Center(
              child: Text(
                'يجب تسجيل الدخول أولاً',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (title == 'المراجع')
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('digital_saved_references')
                          .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, digitalSnapshot) {
                        final digitalDocs = digitalSnapshot.data?.docs ?? [];
                        if (digitalDocs.isEmpty) return const SizedBox.shrink();
                        return _buildDigitalReferenceList(context, digitalDocs);
                      },
                    ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _buildStream(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      return _buildFileList(context, docs);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
