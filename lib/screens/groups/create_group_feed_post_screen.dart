import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';

class CreateGroupFeedPostScreen extends StatefulWidget {
  final GroupModel group;

  const CreateGroupFeedPostScreen({super.key, required this.group});

  @override
  State<CreateGroupFeedPostScreen> createState() => _CreateGroupFeedPostScreenState();
}

class _CreateGroupFeedPostScreenState extends State<CreateGroupFeedPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPublishing = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    setState(() => _isPublishing = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fullPath = 'global_feed/$uid/$timestamp.jpg';

        // 🔍 DIAGNOSTIC LOG — remove after confirming
        debugPrint('──────────────────────────────────');
        debugPrint('[UPLOAD DIAG] uid        = $uid');
        debugPrint('[UPLOAD DIAG] full path  = $fullPath');
        debugPrint('[UPLOAD DIAG] uid valid? = ${uid != 'unknown'}');
        debugPrint('──────────────────────────────────');

        if (uid == 'unknown') {
          throw Exception('المستخدم غير مسجل الدخول — لا يمكن رفع الصورة');
        }

        final ref = FirebaseStorage.instance
            .ref()
            .child('global_feed')
            .child(uid)
            .child('$timestamp.jpg');
        final uploadTask = await ref.putFile(_selectedImage!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      await GroupService.publishGlobalFeedPost(
        group: widget.group,
        text: content,
        imageUrl: imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الإعلان في الفيد العام بنجاح')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("نشر في الفيد العام", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed: _isPublishing || (_contentController.text.trim().isEmpty && _selectedImage == null) ? null : _publishPost,
              child: _isPublishing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("نشر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: widget.group.imageUrl.isNotEmpty ? NetworkImage(widget.group.imageUrl) : null,
                  child: widget.group.imageUrl.isEmpty ? Text(widget.group.name.isNotEmpty ? widget.group.name[0].toUpperCase() : 'G', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                      const Text("إعلان عام للطلاب", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              onChanged: (_) => setState(() {}),
              maxLines: null,
              minLines: 6,
              style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: "ماذا تفكر اليوم؟ شارك تحديثاً عن المجموعة...",
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                border: InputBorder.none,
              ),
            ),
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: double.infinity,
                height: 200,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (_selectedImage == null)
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (image != null) {
                      setState(() {
                        _selectedImage = File(image.path);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text("إضافة صورة", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
