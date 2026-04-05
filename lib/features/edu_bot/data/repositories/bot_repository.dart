import '../../domain/entities/chat_message.dart';
import '../services/bot_remote_service.dart';
import '../models/chat_message_model.dart';

class BotRepository {
  final BotRemoteService _remoteService;

  BotRepository(this._remoteService);

  Future<ChatMessage> sendMessage(String text, List<ChatMessage> history) async {
    final historyPayload = history.map((msg) => {
      'role': msg.sender == MessageSender.user ? 'user' : 'model',
      'text': msg.text,
    }).toList();

    final replyStr = await _remoteService.sendToBot(text, historyPayload);
    
    return ChatMessageModel.fromBotResponse(
      replyStr, 
      DateTime.now().millisecondsSinceEpoch.toString()
    );
  }
}
