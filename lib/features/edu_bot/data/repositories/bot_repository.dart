import '../../domain/entities/chat_message.dart';
import '../services/bot_remote_service.dart';

class BotRepository {
  final BotRemoteService _remoteService;

  BotRepository(this._remoteService);

  Future<ChatMessage> sendMessage(String text, List<ChatMessage> history) async {
    throw UnimplementedError('BotRepository.sendMessage not implemented yet');
  }
}
