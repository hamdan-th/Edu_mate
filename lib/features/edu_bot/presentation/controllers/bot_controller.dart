import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/bot_repository.dart';

class BotController extends ChangeNotifier {
  final BotRepository _repository;
  
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  BotController(this._repository);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  Future<void> sendMessage(String text) async {
    if (_isSending || text.trim().isEmpty) return;
    
    _isSending = true;
    notifyListeners();

    final trimmedText = text.trim();
    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _messages.add(
      ChatMessage(
        id: userMsgId,
        text: trimmedText,
        sender: MessageSender.user,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      ),
    );
    notifyListeners();

    final historyToPass = _messages
        .where((m) => m.id != userMsgId && m.status == MessageStatus.sent)
        .toList();

    try {
      final botReply = await _repository.sendMessage(trimmedText, historyToPass);

      final index = _messages.indexWhere((m) => m.id == userMsgId);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: userMsgId,
          text: trimmedText,
          sender: MessageSender.user,
          createdAt: _messages[index].createdAt,
          status: MessageStatus.sent,
        );
      }

      _messages.add(botReply);
    } catch (e) {
      final String rawError = e.toString().toLowerCase();
      String friendlyError = "عذراً، واجهنا خطأ تقني. يرجى المحاولة لاحقاً.";
      bool canFallback = false;

      if (rawError.contains('resource-exhausted') || rawError.contains('quota') || rawError.contains('429')) {
        friendlyError = "الخدمة تحت ضغط عالي، يرجى المحاولة بعد قليل.";
        canFallback = true;
      } else if (rawError.contains('unavailable') || rawError.contains('network') || rawError.contains('internet')) {
        friendlyError = "لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة.";
      }

      if (canFallback) {
         final String lowerText = trimmedText.toLowerCase();
         String fallbackReply = "";
         if (lowerText.contains("نشر") || lowerText.contains("فيد") || lowerText.contains("post")) {
             fallbackReply = "💡 (وضع الأوفلاين) لنشر بوست: اذهب إلى شاشة الفيد واضغط على زر الإضافة (+).";
         } else if (lowerText.contains("جروب") || lowerText.contains("مجموعة") || lowerText.contains("group")) {
             fallbackReply = "💡 (وضع الأوفلاين) للانضمام للمجموعات: ابحث في قسم Discover أو استخدم دعوة مباشرة.";
         } else if (lowerText.contains("مكتبة") || lowerText.contains("ملف") || lowerText.contains("library")) {
             fallbackReply = "💡 (وضع الأوفلاين) للملفات: افتح قسم المكتبة أسفل الشاشة وابحث عن القسم المناسب.";
         } else {
             fallbackReply = "عذراً، أواجه ضغطاً استثنائياً حالياً ولن أتمكن من إجابة سؤالك المفصل. سأعود للعمل قريباً!";
         }

         final index = _messages.indexWhere((m) => m.id == userMsgId);
         if (index != -1) {
            _messages[index] = ChatMessage(
              id: userMsgId,
              text: trimmedText,
              sender: MessageSender.user,
              createdAt: _messages[index].createdAt,
              status: MessageStatus.sent,
            );
         }
         _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: fallbackReply,
              sender: MessageSender.bot,
              createdAt: DateTime.now(),
              status: MessageStatus.sent,
            )
         );
      } else {
        final index = _messages.indexWhere((m) => m.id == userMsgId);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: userMsgId,
            text: trimmedText,
            sender: MessageSender.user,
            createdAt: _messages[index].createdAt,
            status: MessageStatus.failed,
            errorMessage: friendlyError,
          );
        }
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> retryMessage(String messageId) async {
    if (_isSending) return;
    
    final index = _messages.indexWhere((m) => m.id == messageId && m.status == MessageStatus.failed);
    if (index == -1) return;

    final failedText = _messages[index].text;
    _messages.removeAt(index);
    notifyListeners();

    await sendMessage(failedText);
  }

  void clearChat() {
    _messages.clear();
    _isSending = false;
    notifyListeners();
  }
}
