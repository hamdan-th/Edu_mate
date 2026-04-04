import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPublishing = true);
    try {
      await GroupService.publishGlobalFeedPost(
        group: widget.group,
        text: content,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الإعلان في الفيد العام بنجاح')));
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isPublishing || _contentController.text.trim().isEmpty ? null : _publishPost,
              child: _isPublishing 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("نشر", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إضافة الصور ستكون متاحة قريباً')));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
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
