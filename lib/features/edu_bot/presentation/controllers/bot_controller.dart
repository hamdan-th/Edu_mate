import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../data/repositories/bot_repository.dart';

class BotController extends ChangeNotifier {
  final BotRepository _repository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final List<ChatSession> _sessions = [];
  String? _activeSessionId;
  bool _isSending = false;
  bool _isLoading = true;

  BotController(this._repository) {
    _initDefaultSession();
  }

  Future<void> _initDefaultSession() async {
    await _loadSessions();
  }

  List<ChatSession> get sessions {
    return List.unmodifiable([..._sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  bool get isSending => _isSending;
  bool get isLoading => _isLoading;
  
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
    _saveSession(newSession);
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
    _deleteSessionFirestore(sessionId);
    
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
       final newSession = session.copyWith(messages: updatedMessages, updatedAt: DateTime.now());
       _sessions[sessionIndex] = newSession;
       _saveSession(newSession);
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
       final newSession = _sessions[index].copyWith(messages: const [], title: 'محادثة جديدة', updatedAt: DateTime.now());
       _sessions[index] = newSession;
       _saveSession(newSession);
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
      
      final newSession = session.copyWith(
        messages: newMessages,
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      _sessions[index] = newSession;
      _saveSession(newSession);
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
          final newSession = session.copyWith(
             messages: newMessages,
             updatedAt: DateTime.now(),
          );
          _sessions[sessionIndex] = newSession;
          _saveSession(newSession);
       }
    }
  }

  // --- Firestore Persistence ---

  Future<void> _loadSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bot_sessions')
          .orderBy('updatedAt', descending: true)
          .get();

      if (snap.docs.isEmpty) {
        createNewChat();
      } else {
        _sessions.clear();
        for (var doc in snap.docs) {
          _sessions.add(_sessionFromMap(doc.data(), doc.id));
        }
        _activeSessionId = _sessions.first.id;
      }
    } catch (_) {
      if (_sessions.isEmpty) createNewChat();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(ChatSession session) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bot_sessions')
          .doc(session.id)
          .set(_sessionToMap(session));
    } catch (_) {}
  }

  Future<void> _deleteSessionFirestore(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bot_sessions')
          .doc(sessionId)
          .delete();
    } catch (_) {}
  }

  ChatSession _sessionFromMap(Map<String, dynamic> map, String docId) {
    return ChatSession(
      id: docId,
      title: map['title']?.toString() ?? 'محادثة',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      messages: (map['messages'] as List<dynamic>? ?? [])
          .map((m) => _messageFromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> _sessionToMap(ChatSession session) {
    return {
      'title': session.title,
      'createdAt': session.createdAt.millisecondsSinceEpoch,
      'updatedAt': session.updatedAt.millisecondsSinceEpoch,
      'messages': session.messages.map((m) => _messageToMap(m)).toList(),
    };
  }

  ChatMessage _messageFromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      sender: map['sender'] == 1 ? MessageSender.bot : MessageSender.user,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      // Restore failed/sent. Treat sending as failed if loaded fresh.
      status: map['status'] == 2 ? MessageStatus.failed : MessageStatus.sent,
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  Map<String, dynamic> _messageToMap(ChatMessage msg) {
    return {
      'id': msg.id,
      'text': msg.text,
      'sender': msg.sender == MessageSender.user ? 0 : 1,
      'createdAt': msg.createdAt.millisecondsSinceEpoch,
      'status': (msg.status == MessageStatus.sending || msg.status == MessageStatus.failed) ? 2 : 1,
      if (msg.errorMessage != null) 'errorMessage': msg.errorMessage,
    };
  }
}
