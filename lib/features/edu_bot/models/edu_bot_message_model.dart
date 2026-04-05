class EduBotMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isLoading;

  EduBotMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isLoading = false,
  });
}
