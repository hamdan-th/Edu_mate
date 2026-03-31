// lib/file_details_screen.dart

import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'file_model.dart';

class FileDetailsScreen extends StatefulWidget {
  final FileModel file;
  const FileDetailsScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends State<FileDetailsScreen> {
  late int likesCount;
  late int savesCount;
  bool isLiked = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    likesCount = widget.file.likes;
    savesCount = widget.file.saves;
  }

  @override
  Widget build(BuildContext context) {
    // ✨ 1. تم إزالة Scaffold -> appBar بالكامل
    return Scaffold(
      // ✨ 2. استخدمنا Stack لوضع زر الرجوع فوق الصورة
      body: Stack(
        children: [
          // المحتوى الرئيسي للشاشة
          SingleChildScrollView(
            // padding من الأعلى ليبدأ المحتوى تحت زر الرجوع
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- صورة الملف ---
                // تم وضعها داخل Padding بدلاً من أن تكون بحجم الشاشة الكامل
                Padding(
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16), // ترك مسافة من الأعلى
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(widget.file.thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LibraryTheme.primary.withOpacity(0.10),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),

                // باقي محتوى الشاشة داخل Padding
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // --- عنوان الملف ---
                      Text(
                        widget.file.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // --- اسم المؤلف ---
                      Text(
                        'بواسطة: ${widget.file.author}',
                        style: TextStyle(fontSize: 18, color: LibraryTheme.muted),
                      ),
                      const SizedBox(height: 24),

                      // --- أزرار الإجراءات (التفاعلية) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // زر الإعجاب
                          _buildActionButton(
                            icon: isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                            label: 'إعجاب',
                            count: likesCount,
                            isActive: isLiked,
                            // --- تأكد من أن هذا الكود موجود هنا ---
                            onTap: () {
                              setState(() {
                                if (isLiked) {
                                  likesCount--;
                                } else {
                                  likesCount++;
                                }
                                isLiked = !isLiked;
                              });
                            },
                            // ------------------------------------
                          ),

                          // زر الحفظ
                          _buildActionButton(
                            icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            label: 'حفظ',
                            count: savesCount,
                            isActive: isSaved,
                            // --- تأكد من أن هذا الكود موجود هنا ---
                            onTap: () {
                              setState(() {
                                if (isSaved) {
                                  savesCount--;
                                } else {
                                  savesCount++;
                                }
                                isSaved = !isSaved;
                              });
                            },
                            // ------------------------------------
                          ),

                          _buildActionButton(
                            icon: Icons.share_outlined,
                            label: 'نشر',
                            onTap: () => print('زر النشر تم الضغط عليه'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // --- معلومات الملف ---
                      const Text('معلومات الملف', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildInfoRow('المادة:', widget.file.course),
                      _buildInfoRow('الجامعة:', widget.file.university),
                      _buildInfoRow('الكلية:', widget.file.college),
                      _buildInfoRow('التخصص:', widget.file.major),
                      _buildInfoRow('الفصل الدراسي:', widget.file.semester),
                      _buildInfoRow('نوع الملف:', widget.file.fileType),
                      const SizedBox(height: 32),

                      // ✨ 3. إضافة زر التنزيل بجانب زر التصفح
                      Row(
                        children: [
                          // زر التصفح
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.remove_red_eye_outlined),
                              label: const Text('تصفح'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LibraryTheme.secondary, // لون ثانوي
                                foregroundColor: LibraryTheme.surface,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => print('زر تصفح الملف تم الضغط عليه'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // زر التنزيل
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('تنزيل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LibraryTheme.primary, // اللون الأساسي
                                foregroundColor: LibraryTheme.surface,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => print('زر تنزيل الملف تم الضغط عليه'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✨ 4. زر الرجوع العائم في الأعلى
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: LibraryTheme.text.withOpacity(0.28),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: LibraryTheme.surface, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({ required IconData icon, required String label, required VoidCallback onTap, int? count, bool isActive = false }) {
    final color = isActive ? LibraryTheme.primary : LibraryTheme.muted;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            count != null ? '$label ($count)' : label,
            style: TextStyle(fontSize: 14, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: LibraryTheme.text.withOpacity(0.72)))),
        ],
      ),
    );
  }
}
