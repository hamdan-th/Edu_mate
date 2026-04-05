import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.sender,
    required super.createdAt,
    super.status = MessageStatus.sent,
    super.errorMessage,
  });

  factory ChatMessageModel.fromBotResponse(String replyText, String id) {
    return ChatMessageModel(
      id: id,
      text: replyText,
      sender: MessageSender.bot,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
  }
}
