enum MessageSender { user, bot }
enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime createdAt;
  final MessageStatus status;
  final String? errorMessage;
  final List<Map<String, dynamic>>? suggestedFiles;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.errorMessage,
    this.suggestedFiles,
  });
}
