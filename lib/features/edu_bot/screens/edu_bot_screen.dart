import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/edu_bot_message_model.dart';
import '../services/edu_bot_service.dart';

class EduBotScreen extends StatefulWidget {
  const EduBotScreen({super.key});

  @override
  State<EduBotScreen> createState() => _EduBotScreenState();
}

class _EduBotScreenState extends State<EduBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<EduBotMessageModel> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Insert initial safe welcome message locally.
    _messages.add(
      EduBotMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'مرحباً! أنا مساعِدك الذكي Edu Bot 👋\nكيف يمكنني مساعدتك اليوم؟',
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsgText = text.trim();
    _messageController.clear();

    final userMsg = EduBotMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMsgText,
      isUser: true,
      createdAt: DateTime.now(),
    );

    final loadingId = 'loading_${DateTime.now().millisecondsSinceEpoch}';
    final loadingMsg = EduBotMessageModel(
      id: loadingId,
      text: '',
      isUser: false,
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    final botReply = await EduBotService.sendMessage(userMsgText);

    if (mounted) {
      setState(() {
        _messages.removeWhere((m) => m.id == loadingId);
        _messages.add(
          EduBotMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: botReply,
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => _handleSendMessage(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Column(
          children: [
            Text(
              'Edu Bot',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'مساعدك الذكي دائم الجاهزية',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.isUser;

                if (message.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10, left: 60),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 4 : 20),
                        bottomRight: Radius.circular(isUser ? 20 : 4),
                      ),
                      border: isUser ? null : Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: (isUser ? AppColors.primary : AppColors.textPrimary).withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.55,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildSuggestionChip('كيف أنضم لمجموعة؟'),
                  _buildSuggestionChip('كيف أنشر في الفيد؟'),
                  _buildSuggestionChip('كيف أستخدم المكتبة؟'),
                  _buildSuggestionChip('كيف أبدأ محادثة دراسية؟'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _isLoading ? null : () => _handleSendMessage(_messageController.text),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isLoading ? AppColors.border : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!_isLoading)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: _isLoading 
                       ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                       : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
