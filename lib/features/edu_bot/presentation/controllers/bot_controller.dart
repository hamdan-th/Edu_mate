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
    
    throw UnimplementedError('BotController.sendMessage not implemented yet');
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
