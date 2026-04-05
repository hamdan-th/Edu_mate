import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../data/repositories/bot_repository.dart';

class BotController extends ChangeNotifier {
  final BotRepository _repository;
  
  final List<ChatSession> _sessions = [];
  String? _activeSessionId;
  bool _isSending = false;

  BotController(this._repository) {
    _initDefaultSession();
  }

  void _initDefaultSession() {
    if (_sessions.isEmpty) {
      createNewChat();
    }
  }

  List<ChatSession> get sessions {
    return List.unmodifiable([..._sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  bool get isSending => _isSending;
  
  ChatSession? get activeSession {
    if (_activeSessionId == null) return null;
    final index = _sessions.indexWhere((s) => s.id == _activeSessionId);
    return index != -1 ? _sessions[index] : null;
  }
  
  List<ChatMessage> get messages => activeSession?.messages ?? [];

  void createNewChat() {
    if (_isSending) return;
    
    if (activeSession != null && activeSession!.messages.isEmpty) {
      return; 
    }

    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'محادثة جديدة',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: const [],
    );
    _sessions.add(newSession);
    _activeSessionId = newSession.id;
    notifyListeners();
  }

  void openChat(String sessionId) {
    if (_isSending) return;
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _activeSessionId = sessionId;
      notifyListeners();
    }
  }

  void deleteChat(String sessionId) {
    if (_isSending && _activeSessionId == sessionId) return;

    _sessions.removeWhere((s) => s.id == sessionId);
    
    if (_sessions.isEmpty) {
      createNewChat();
    } else if (_activeSessionId == sessionId) {
      _activeSessionId = sessions.first.id;
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_isSending || text.trim().isEmpty || activeSession == null) return;
    
    _isSending = true;
    notifyListeners();

    final trimmedText = text.trim();
    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final curSessionId = _activeSessionId!;
    
    _appendMessageToSession(
      curSessionId,
      ChatMessage(
        id: userMsgId,
        text: trimmedText,
        sender: MessageSender.user,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      ),
      updateTitle: trimmedText,
    );
    notifyListeners();

    final currentSession = _sessions.firstWhere((s) => s.id == curSessionId, orElse: () => _sessions.first);
    final historyToPass = currentSession.messages
        .where((m) => m.id != userMsgId && m.status == MessageStatus.sent)
        .toList();

    try {
      final botReply = await _repository.sendMessage(trimmedText, historyToPass);

      _updateMessageInSession(
        curSessionId,
        userMsgId,
        (msg) => ChatMessage(
          id: msg.id,
          text: msg.text,
          sender: msg.sender,
          createdAt: msg.createdAt,
          status: MessageStatus.sent,
        ),
      );

      _appendMessageToSession(curSessionId, botReply);
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

         _updateMessageInSession(
           curSessionId,
           userMsgId,
           (msg) => ChatMessage(
             id: msg.id,
             text: msg.text,
             sender: msg.sender,
             createdAt: msg.createdAt,
             status: MessageStatus.sent,
           ),
         );
         
         _appendMessageToSession(
           curSessionId,
           ChatMessage(
             id: DateTime.now().millisecondsSinceEpoch.toString(),
             text: fallbackReply,
             sender: MessageSender.bot,
             createdAt: DateTime.now(),
             status: MessageStatus.sent,
           )
         );
      } else {
         _updateMessageInSession(
           curSessionId,
           userMsgId,
           (msg) => ChatMessage(
             id: msg.id,
             text: msg.text,
             sender: msg.sender,
             createdAt: msg.createdAt,
             status: MessageStatus.failed,
             errorMessage: friendlyError,
           ),
         );
      }
    } finally {
      if (_activeSessionId == curSessionId) {
        _isSending = false;
      } else {
         _isSending = false; 
      }
      notifyListeners();
    }
  }

  Future<void> retryMessage(String messageId) async {
    if (_isSending || activeSession == null) return;
    
    final curSessionId = _activeSessionId!;
    final index = activeSession!.messages.indexWhere((m) => m.id == messageId && m.status == MessageStatus.failed);
    if (index == -1) return;

    final failedText = activeSession!.messages[index].text;
    
    final sessionIndex = _sessions.indexWhere((s) => s.id == curSessionId);
    if (sessionIndex != -1) {
       final session = _sessions[sessionIndex];
       final updatedMessages = List<ChatMessage>.from(session.messages)..removeAt(index);
       _sessions[sessionIndex] = session.copyWith(messages: updatedMessages, updatedAt: DateTime.now());
       notifyListeners();
    }

    await sendMessage(failedText);
  }

  void clearChatConfirm(BuildContext context) {
    if (activeSession == null || activeSession!.messages.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('مسح المحادثة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('هل أنت متأكد أنك تريد مسح جميع رسائل هذه المحادثة؟', style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
               _clearCurrentChat();
               Navigator.pop(context);
            },
            child: const Text('مسح', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _clearCurrentChat() {
    if (_activeSessionId == null) return;
    final index = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (index != -1) {
       _sessions[index] = _sessions[index].copyWith(messages: const [], title: 'محادثة جديدة', updatedAt: DateTime.now());
       notifyListeners();
    }
  }

  void _appendMessageToSession(String sessionId, ChatMessage message, {String? updateTitle}) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _sessions[index];
      final newMessages = List<ChatMessage>.from(session.messages)..add(message);
      
      String newTitle = session.title;
      if (updateTitle != null && session.messages.isEmpty) {
        newTitle = updateTitle.length > 25 ? '${updateTitle.substring(0, 25)}...' : updateTitle;
      }
      
      _sessions[index] = session.copyWith(
        messages: newMessages,
        title: newTitle,
        updatedAt: DateTime.now(),
      );
    }
  }

  void _updateMessageInSession(String sessionId, String messageId, ChatMessage Function(ChatMessage) update) {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
       final session = _sessions[sessionIndex];
       final msgIndex = session.messages.indexWhere((m) => m.id == messageId);
       if (msgIndex != -1) {
          final newMessages = List<ChatMessage>.from(session.messages);
          newMessages[msgIndex] = update(newMessages[msgIndex]);
          _sessions[sessionIndex] = session.copyWith(
             messages: newMessages,
             updatedAt: DateTime.now(),
          );
       }
    }
  }
}
