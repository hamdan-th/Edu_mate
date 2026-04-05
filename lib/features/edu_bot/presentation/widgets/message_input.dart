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
      setState((){});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
               BoxShadow(
                 color: AppColors.textPrimary.withOpacity(0.03),
                 blurRadius: 10,
                 offset: const Offset(0, 2),
               )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(
                    hintText: 'اسأل Edu Bot أي شيء...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 6, bottom: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: (hasText && !widget.isSending)
                      ? const LinearGradient(colors: [AppColors.primary, AppColors.blueGlow], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                    color: (hasText && !widget.isSending) ? null : AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (hasText && !widget.isSending)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: InkWell(
                    onTap: (hasText && !widget.isSending) ? _handleSend : null,
                    borderRadius: BorderRadius.circular(22),
                    child: widget.isSending 
                       ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                       : Icon(Icons.arrow_upward_rounded, color: (hasText && !widget.isSending) ? Colors.white : AppColors.textSecondary.withOpacity(0.5), size: 20),
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
