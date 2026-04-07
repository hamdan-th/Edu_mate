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
  const MyFilesListScreen({super.key, required this.title});

  FileModel _mapDocToFileModel(Map<String, dynamic> data, String docId) {
    final subjectName = (data['subjectName'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†').toString();
    final doctorName = (data['doctorName'] ?? 'ط؛ظٹط± ظ…ط¹ط±ظˆظپ').toString();
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
      university: 'ط¬ط§ظ…ط¹ط© طµظ†ط¹ط§ط،',
      college: college,
      major: specialization,
      semester: '$level${term.isNotEmpty ? ' â€¢ $term' : ''}',
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
        const SnackBar(content: Text('ظ„ط§ ظٹظˆط¬ط¯ ط±ط§ط¨ط· ظ„ظ„ظ…ظ„ظپ')),
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
        const SnackBar(content: Text('طھط¹ط°ط± ظپطھط­ ط§ظ„ظ…ظ„ظپ')),
      );
    }
  }

  Widget _buildFileList(
      BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    String emptyMessage = 'ظ„ط§ طھظˆط¬ط¯ ظ…ظ„ظپط§طھ';
    if (title == 'ط§ظ„ظ…ط±ط§ط¬ط¹') emptyMessage = 'ظ„ظ… طھظ‚ظ… ط¨ط­ظپط¸ ط£ظٹ ظ…ظ„ظپط§طھ ط¨ط¹ط¯';
    if (title == 'ظ…ط§ ط±ظپط¹طھظ‡') emptyMessage = 'ظ„ظ… طھظ‚ظ… ط¨ط±ظپط¹ ط£ظٹ ظ…ظ„ظپط§طھ ط¨ط¹ط¯';
    if (title == 'طھظ†ط²ظٹظ„ط§طھظٹ') emptyMessage = 'ظ„ظ… طھظ‚ظ… ط¨طھظ†ط²ظٹظ„ ط£ظٹ ظ…ظ„ظپط§طھ ط¨ط¹ط¯';
    if (title == 'ظ…ط§ ط´ط§ط±ظƒطھظ‡') emptyMessage = 'ظ„ظ… طھظ‚ظ… ط¨ظ…ط´ط§ط±ظƒط© ط£ظٹ ظ…ظ„ظپط§طھ ط¨ط¹ط¯';

    if (docs.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            fontSize: 18,
            color: LibraryTheme.text(context),
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
            if (title == 'طھظ†ط²ظٹظ„ط§طھظٹ') {
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
              color: LibraryTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LibraryTheme.border(context)),
              boxShadow: [
                BoxShadow(
                  color: LibraryTheme.primary(context).withOpacity(0.04),
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
                  color: (isPdf ? LibraryTheme.danger(context) : LibraryTheme.primary(context))
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.description_rounded,
                  color: isPdf ? LibraryTheme.danger(context) : LibraryTheme.primary(context),
                ),
              ),
              title: Text(
                data['subjectName'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: LibraryTheme.text(context),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${data['doctorName'] ?? ''} â€¢ ${data['college'] ?? ''}',
                  style: TextStyle(
                    color: LibraryTheme.muted(context),
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
                      color: LibraryTheme.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (data['term'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: LibraryTheme.muted(context),
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

  Widget _buildMyUploads(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: LibraryFilesService.myUploadedFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ط­ط¯ط« ط®ط·ط£: ${snapshot.error}',
              style: TextStyle(color: LibraryTheme.text(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        return _buildFileList(context, docs);
      },
    );
  }

  Widget _buildSavedReferences(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'ظٹط¬ط¨ طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„ ط£ظˆظ„ط§ظ‹',
          style: TextStyle(fontSize: 18, color: LibraryTheme.text(context)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('saves')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, saveSnapshot) {
        if (saveSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (saveSnapshot.hasError) {
          return Center(
            child: Text(
              'ط­ط¯ط« ط®ط·ط£: ${saveSnapshot.error}',
              style: TextStyle(color: LibraryTheme.text(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        final saveDocs = saveSnapshot.data?.docs ?? [];

        return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _loadParentFileDocs(saveDocs),
          builder: (context, filesSnapshot) {
            if (filesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filesSnapshot.hasError) {
              return Center(
                child: Text(
                  'ط­ط¯ط« ط®ط·ط£: ${filesSnapshot.error}',
                  style: TextStyle(color: LibraryTheme.text(context)),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final fileDocs = filesSnapshot.data ?? [];
            if (fileDocs.isEmpty) return const SizedBox.shrink();
            return _buildFileList(context, fileDocs);
          },
        );
      },
    );
  }

  Widget _buildDownloads(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'ظٹط¬ط¨ طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„ ط£ظˆظ„ط§ظ‹',
          style: TextStyle(fontSize: 18, color: LibraryTheme.text(context)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('downloads')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, downloadSnapshot) {
        if (downloadSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (downloadSnapshot.hasError) {
          return Center(
            child: Text(
              'ط­ط¯ط« ط®ط·ط£: ${downloadSnapshot.error}',
              style: TextStyle(color: LibraryTheme.text(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        final downloadDocs = downloadSnapshot.data?.docs ?? [];

        return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _loadParentFileDocs(downloadDocs),
          builder: (context, filesSnapshot) {
            if (filesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filesSnapshot.hasError) {
              return Center(
                child: Text(
                  'ط­ط¯ط« ط®ط·ط£: ${filesSnapshot.error}',
                  style: TextStyle(color: LibraryTheme.text(context)),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final fileDocs = filesSnapshot.data ?? [];
            if (fileDocs.isEmpty) return const SizedBox.shrink();
            return _buildFileList(context, fileDocs);
          },
        );
      },
    );
  }

  Widget _buildShares(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'ظٹط¬ط¨ طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„ ط£ظˆظ„ط§ظ‹',
          style: TextStyle(fontSize: 18, color: LibraryTheme.text(context)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('shares')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, shareSnapshot) {
        if (shareSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (shareSnapshot.hasError) {
          return Center(
            child: Text(
              'ط­ط¯ط« ط®ط·ط£: ${shareSnapshot.error}',
              style: TextStyle(color: LibraryTheme.text(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        final shareDocs = shareSnapshot.data?.docs ?? [];

        return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _loadParentFileDocs(shareDocs),
          builder: (context, filesSnapshot) {
            if (filesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filesSnapshot.hasError) {
              return Center(
                child: Text(
                  'ط­ط¯ط« ط®ط·ط£: ${filesSnapshot.error}',
                  style: TextStyle(color: LibraryTheme.text(context)),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final fileDocs = filesSnapshot.data ?? [];
            return _buildFileList(context, fileDocs);
          },
        );
      },
    );
  }

  Widget _buildDigitalSavedReferences(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DigitalLibraryFirestoreService.savedReferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ط­ط¯ط« ط®ط·ط£: ${snapshot.error}',
              style: TextStyle(color: LibraryTheme.text(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final coreResult = _mapDigitalDocToCoreResult(data);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoreResultDetailsScreen(
                      resultData: coreResult,
                      isSaved: true,
                      onToggleSave: () {},
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LibraryTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LibraryTheme.border(context)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: LibraryTheme.primary(context).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: LibraryTheme.primary(context),
                    ),
                  ),
                  title: Text(
                    (data['title'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†').toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: LibraryTheme.text(context),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      (data['authors'] ?? 'ظ…ط¤ظ„ظپ ط؛ظٹط± ظ…ط¹ط±ظˆظپ').toString(),
                      style: TextStyle(
                        color: LibraryTheme.muted(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                  trailing: Text(
                    'CORE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: LibraryTheme.primary(context),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDigitalDownloads(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DigitalLibraryFirestoreService.downloadedReferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ط­ط¯ط« ط®ط·ط£: ${snapshot.error}',
              style: TextStyle(color: LibraryTheme.text(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();

            return GestureDetector(
              onTap: () async {
                final downloadUrl = (data['downloadUrl'] ?? '').toString();
                final sourceUrl = (data['sourceUrl'] ?? '').toString();
                final targetUrl =
                downloadUrl.isNotEmpty ? downloadUrl : sourceUrl;

                if (targetUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ظ„ط§ ظٹظˆط¬ط¯ ط±ط§ط¨ط· ظ„ظ„ظپطھط­')),
                  );
                  return;
                }

                final uri = Uri.parse(targetUrl);
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );

                if (!launched) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('طھط¹ط°ط± ظپطھط­ ط§ظ„ظ…ظ„ظپ')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LibraryTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LibraryTheme.border(context)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: LibraryTheme.primary(context).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: LibraryTheme.primary(context),
                    ),
                  ),
                  title: Text(
                    (data['title'] ?? 'ط¨ط¯ظˆظ† ط¹ظ†ظˆط§ظ†').toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: LibraryTheme.text(context),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      (data['authors'] ?? 'ظ…ط¤ظ„ظپ ط؛ظٹط± ظ…ط¹ط±ظˆظپ').toString(),
                      style: TextStyle(
                        color: LibraryTheme.muted(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                  trailing: Text(
                    'ظپطھط­',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: LibraryTheme.primary(context),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadParentFileDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> childDocs,
      ) async {
    final results = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final childDoc in childDocs) {
      final fileRef = childDoc.reference.parent.parent;
      if (fileRef == null) continue;

      final fileSnap = await fileRef.get();
      if (fileSnap.exists && fileSnap.data() != null) {
        results.add(_WrappedQueryDocumentSnapshot(fileSnap));
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyUploads = title == 'ظ…ط§ ط±ظپط¹طھظ‡';
    final bool isReferences = title == 'ط§ظ„ظ…ط±ط§ط¬ط¹';
    final bool isDownloads = title == 'طھظ†ط²ظٹظ„ط§طھظٹ';
    final bool isShares = title == 'ظ…ط§ ط´ط§ط±ظƒطھظ‡';

    return Scaffold(
      backgroundColor: LibraryTheme.bg(context),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: LibraryTheme.surface(context),
        foregroundColor: LibraryTheme.text(context),
        elevation: 0,
      ),
      body: isMyUploads
          ? _buildMyUploads(context)
          : isReferences
          ? SingleChildScrollView(
        child: Column(
          children: [
            _buildSavedReferences(context),
            _buildDigitalSavedReferences(context),
          ],
        ),
      )
          : isDownloads
          ? SingleChildScrollView(
        child: Column(
          children: [
            _buildDownloads(context),
            _buildDigitalDownloads(context),
          ],
        ),
      )
          : isShares
          ? _buildShares(context)
          : Center(
        child: Text(
          'ط³ظٹطھظ… ط¹ط±ط¶ ظ‚ط§ط¦ظ…ط© "$title" ظ‡ظ†ط§ ظ„ط§ط­ظ‚ظ‹ط§',
          style: TextStyle(
            fontSize: 18,
            color: LibraryTheme.text(context),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _WrappedQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final DocumentSnapshot<Map<String, dynamic>> _doc;

  _WrappedQueryDocumentSnapshot(this._doc);

  @override
  Map<String, dynamic> data() => _doc.data()!;

  @override
  String get id => _doc.id;

  @override
  DocumentReference<Map<String, dynamic>> get reference => _doc.reference;

  @override
  SnapshotMetadata get metadata => _doc.metadata;

  @override
  bool get exists => _doc.exists;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

