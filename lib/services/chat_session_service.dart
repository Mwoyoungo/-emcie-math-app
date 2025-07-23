import 'package:flutter/foundation.dart';
import '../screens/chat/components/chat_message.dart';
import 'supabase_service.dart';

class ChatSession {
  final String chatId;
  final String userId;
  final String topicTitle;
  final String grade;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final List<ChatMessage> messages;
  final Map<String, dynamic> metadata;

  ChatSession({
    required this.chatId,
    required this.userId,
    required this.topicTitle,
    required this.grade,
    required this.createdAt,
    required this.lastActiveAt,
    required this.messages,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'userId': userId,
      'topicTitle': topicTitle,
      'grade': grade,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      chatId: json['chatId'],
      userId: json['userId'],
      topicTitle: json['topicTitle'],
      grade: json['grade'],
      createdAt: DateTime.parse(json['createdAt']),
      lastActiveAt: DateTime.parse(json['lastActiveAt']),
      messages: (json['messages'] as List)
          .map((msgJson) => ChatMessage.fromJson(msgJson))
          .toList(),
      metadata: json['metadata'] ?? {},
    );
  }

  ChatSession copyWith({
    String? chatId,
    String? userId,
    String? topicTitle,
    String? grade,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    List<ChatMessage>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return ChatSession(
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      topicTitle: topicTitle ?? this.topicTitle,
      grade: grade ?? this.grade,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ChatSessionService extends ChangeNotifier {
  ChatSession? _currentSession;
  final Map<String, ChatSession> _sessions = {};


  ChatSession? get currentSession => _currentSession;
  Map<String, ChatSession> get sessions => Map.unmodifiable(_sessions);

  Future<void> initialize() async {
    // In-memory storage - no need for async initialization
    debugPrint('ChatSessionService initialized with in-memory storage');
  }

  String _generateChatId() {
    return 'chat_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
            length, (index) => chars[DateTime.now().millisecond % chars.length])
        .join();
  }

  Future<ChatSession> createNewSession({
    required String userId,
    required String topicTitle,
    required String grade,
  }) async {
    final chatId = _generateChatId();
    final now = DateTime.now();

    final session = ChatSession(
      chatId: chatId,
      userId: userId,
      topicTitle: topicTitle,
      grade: grade,
      createdAt: now,
      lastActiveAt: now,
      messages: [],
      metadata: {
        'assessmentStarted': false,
        'topicProgress': 0.0,
        'lastExecutionId': null,
      },
    );

    _sessions[chatId] = session;
    _currentSession = session;

    debugPrint('Created new session: $chatId for topic: $topicTitle');
    notifyListeners();
    return session;
  }

  Future<ChatSession?> resumeSession({
    required String userId,
    required String topicTitle,
  }) async {
    // First try loading from database for persistence
    try {
      final dbSessions = await SupabaseService.instance.getUserChatSessions(userId);
      final existingDbSession = dbSessions.where(
        (session) => session.topicTitle == topicTitle
      ).firstOrNull;
      
      if (existingDbSession != null) {
        _currentSession = existingDbSession.copyWith(lastActiveAt: DateTime.now());
        _sessions[existingDbSession.chatId] = _currentSession!;
        debugPrint('✅ Loaded session from database: ${existingDbSession.chatId} with ${existingDbSession.messages.length} messages');
        notifyListeners();
        return _currentSession;
      }
    } catch (e) {
      debugPrint('❌ Failed to load from database, using in-memory: $e');
    }

    // Fallback: Look for existing session in memory
    ChatSession? existingSession;

    for (final session in _sessions.values) {
      if (session.userId == userId && session.topicTitle == topicTitle) {
        existingSession = session;
        break;
      }
    }

    if (existingSession != null) {
      _currentSession = existingSession.copyWith(lastActiveAt: DateTime.now());
      _sessions[existingSession.chatId] = _currentSession!;

      debugPrint(
          'Resumed session: ${existingSession.chatId} for topic: $topicTitle with ${existingSession.messages.length} messages');
      notifyListeners();
      return _currentSession;
    }

    debugPrint('No existing session found for topic: $topicTitle');
    return null;
  }

  Future<void> addMessage(ChatMessage message, {String? executionId, String? aiChatId}) async {
    if (_currentSession == null) return;

    final updatedMessages = List<ChatMessage>.from(_currentSession!.messages)
      ..add(message);

    final metadata = Map<String, dynamic>.from(_currentSession!.metadata);
    if (executionId != null) {
      metadata['lastExecutionId'] = executionId;
    }
    if (aiChatId != null && aiChatId.isNotEmpty) {
      metadata['flowiseAiChatId'] = aiChatId;
    }

    _currentSession = _currentSession!.copyWith(
      messages: updatedMessages,
      lastActiveAt: DateTime.now(),
      metadata: metadata,
    );

    _sessions[_currentSession!.chatId] = _currentSession!;

    // Save to database in background for persistence
    _saveToDatabase(_currentSession!);

    debugPrint(
        'Added message to session ${_currentSession!.chatId}: ${message.text.length > 50 ? "${message.text.substring(0, 50)}..." : message.text}');
    notifyListeners();
  }

  Future<void> updateSessionMetadata(Map<String, dynamic> updates) async {
    if (_currentSession == null) return;

    final metadata = Map<String, dynamic>.from(_currentSession!.metadata);
    metadata.addAll(updates);

    _currentSession = _currentSession!.copyWith(
      metadata: metadata,
      lastActiveAt: DateTime.now(),
    );

    _sessions[_currentSession!.chatId] = _currentSession!;

    debugPrint('Updated session metadata: $updates');
    notifyListeners();
  }

  Future<void> deleteSession(String chatId) async {
    _sessions.remove(chatId);

    if (_currentSession?.chatId == chatId) {
      _currentSession = null;
    }

    debugPrint('Deleted session: $chatId');
    notifyListeners();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    _currentSession = null;

    debugPrint('Cleared all sessions');
    notifyListeners();
  }

  List<ChatSession> getSessionsForUser(String userId) {
    return _sessions.values
        .where((session) => session.userId == userId)
        .toList()
      ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
  }

  List<ChatSession> getSessionsForTopic(String userId, String topicTitle) {
    return _sessions.values
        .where((session) =>
            session.userId == userId && session.topicTitle == topicTitle)
        .toList()
      ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
  }

  // Get session summary for debugging
  String getSessionSummary() {
    final sessionCount = _sessions.length;
    final activeSession = _currentSession;

    if (sessionCount == 0) {
      return 'No sessions available';
    }

    final buffer = StringBuffer();
    buffer.writeln('Sessions ($sessionCount):');

    for (final session in _sessions.values) {
      final isActive = session.chatId == activeSession?.chatId;
      final messageCount = session.messages.length;
      buffer.writeln(
          '  ${isActive ? "➤" : "-"} ${session.topicTitle}: $messageCount messages (${session.chatId.substring(0, 8)}...)');
    }

    return buffer.toString();
  }

  // Check if session exists for topic
  bool hasSessionForTopic(String userId, String topicTitle) {
    return _sessions.values.any((session) =>
        session.userId == userId && session.topicTitle == topicTitle);
  }

  // Background database save - non-blocking for performance
  void _saveToDatabase(ChatSession session) {
    // Run in background to avoid blocking UI
    Future.microtask(() async {
      try {
        await SupabaseService.instance.saveChatSession(session);
        debugPrint('✅ Session saved to database: ${session.chatId}');
      } catch (e) {
        debugPrint('❌ Database save failed (continuing with in-memory): $e');
        // Continue with in-memory storage as fallback
      }
    });
  }
}
