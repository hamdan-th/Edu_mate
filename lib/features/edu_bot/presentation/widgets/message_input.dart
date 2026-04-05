import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isSending;

  const MessageInput({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    if (widget.isSending) return;
    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border.withOpacity(0.8)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'اسأل Edu Bot أي شيء...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.5),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: widget.isSending ? null : _handleSend,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: widget.isSending 
                  ? null 
                  : const LinearGradient(colors: [AppColors.primary, AppColors.blueGlow], begin: Alignment.topLeft, end: Alignment.bottomRight),
                color: widget.isSending ? AppColors.border : null,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!widget.isSending)
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: widget.isSending 
                 ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                 : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
