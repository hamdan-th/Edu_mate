import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/group_service.dart';

class JoinPrivateGroupScreen extends StatefulWidget {
  const JoinPrivateGroupScreen({super.key});

  @override
  State<JoinPrivateGroupScreen> createState() => _JoinPrivateGroupScreenState();
}

class _JoinPrivateGroupScreenState extends State<JoinPrivateGroupScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final inviteLink = _linkController.text.trim();

    if (inviteLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ألصق رابط الدعوة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await GroupService.joinPrivateGroupByLink(inviteLink);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام للمجموعة بنجاح')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الانضمام برابط دعوة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.link_rounded,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'الصق رابط الدعوة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكنك الانضمام إلى المجموعة الخاصة عبر رابط الدعوة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'رابط الدعوة',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _join,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _isLoading ? 'جاري الانضمام...' : 'انضمام',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
