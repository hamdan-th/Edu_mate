import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group_model.dart';
import '../../core/theme/app_colors.dart';

class CreateGroupFeedPostScreen extends StatefulWidget {
  final GroupModel group;
  
  const CreateGroupFeedPostScreen({super.key, required this.group});

  @override
  State<CreateGroupFeedPostScreen> createState() => _CreateGroupFeedPostScreenState();
}

class _CreateGroupFeedPostScreenState extends State<CreateGroupFeedPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // In a real app we might fetch the user's name from firestore
      // For now we'll use a generic "مشرف" or auth display name
      final authorName = user.displayName?.isEmpty == false ? user.displayName! : "إدارة المجموعة";

      await FirebaseFirestore.instance.collection('feed_posts').add({
        'groupId': widget.group.id,
        'groupName': widget.group.name,
        'groupImageUrl': widget.group.imageUrl,
        'authorUserId': user.uid,
        'authorName': authorName,
        'content': content,
        'imageUrl': null, // optional image upload not implemented in this mock phase
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'group_public',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الإعلان في الفيد العام بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء النشر')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("إنشاء إعلان", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("نشر", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
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
                  child: widget.group.imageUrl.isEmpty
                      ? Text(widget.group.name.isNotEmpty ? widget.group.name[0] : 'M')
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("عام - سيظهر لجميع المستخدمين", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: "اكتب إعلانك أو تحديثك هنا ليظهر في الفيد العام...",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رفع الصور سيكون متاحاً قريباً')));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text("إضافة صورة (اختياري)", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
