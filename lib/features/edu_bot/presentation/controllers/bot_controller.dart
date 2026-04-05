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
      final index = _messages.indexWhere((m) => m.id == userMsgId);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: userMsgId,
          text: trimmedText,
          sender: MessageSender.user,
          createdAt: _messages[index].createdAt,
          status: MessageStatus.failed,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _isSending = false;
    notifyListeners();
  }
}
