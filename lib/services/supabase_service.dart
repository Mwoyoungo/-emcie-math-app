import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'performance_service.dart';
import 'chat_session_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  
  // Initialize Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }

  // User Authentication
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String grade,
    String role = 'student',
    String? subjectSpecialization,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'grade': grade,
        },
      );

      if (response.user != null) {
        // Create user profile in database
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          grade: grade,
          role: role,
          subjectSpecialization: subjectSpecialization,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Supabase SignUp Error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Supabase SignIn Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase SignOut Error: $e');
      rethrow;
    }
  }

  // User Profile Management
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String grade,
    String role = 'student',
    String? subjectSpecialization,
  }) async {
    try {
      await client.from('user_profiles').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'role': role,
        'grade': role == 'student' ? grade : null,
        'subject_specialization': role == 'teacher' ? subjectSpecialization : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Create User Profile Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Get User Profile Error: $e');
      return null;
    }
  }

  // Chat Session Management
  Future<void> saveChatSession(ChatSession session) async {
    try {
      await client.from('chat_sessions').upsert({
        'id': session.chatId,
        'user_id': session.userId,
        'topic_title': session.topicTitle,
        'grade': session.grade,
        'created_at': session.createdAt.toIso8601String(),
        'last_active_at': session.lastActiveAt.toIso8601String(),
        'messages': session.messages.map((msg) => msg.toJson()).toList(),
        'metadata': session.metadata,
      });
    } catch (e) {
      debugPrint('Save Chat Session Error: $e');
      rethrow;
    }
  }

  Future<List<ChatSession>> getUserChatSessions(String userId) async {
    try {
      final response = await client
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('last_active_at', ascending: false);

      return response.map<ChatSession>((data) => ChatSession.fromJson({
        'chatId': data['id'],
        'userId': data['user_id'],
        'topicTitle': data['topic_title'],
        'grade': data['grade'],
        'createdAt': data['created_at'],
        'lastActiveAt': data['last_active_at'],
        'messages': data['messages'] ?? [],
        'metadata': data['metadata'] ?? {},
      })).toList();
    } catch (e) {
      debugPrint('Get User Chat Sessions Error: $e');
      return [];
    }
  }

  // Performance Tracking
  Future<void> saveQuestionResult(QuestionResult result) async {
    try {
      await client.from('question_results').insert({
        'id': '${result.executionId}_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': getCurrentUserId(),
        'topic_title': result.topicTitle,
        'question_text': result.questionText,
        'user_answer': result.userAnswer,
        'is_correct': result.isCorrect,
        'timestamp': result.timestamp.toIso8601String(),
        'execution_id': result.executionId,
      });
    } catch (e) {
      debugPrint('Save Question Result Error: $e');
      rethrow;
    }
  }

  Future<List<QuestionResult>> getUserPerformance(String userId) async {
    try {
      final response = await client
          .from('question_results')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return response.map<QuestionResult>((data) => QuestionResult.fromJson({
        'questionText': data['question_text'],
        'userAnswer': data['user_answer'],
        'isCorrect': data['is_correct'],
        'timestamp': data['timestamp'],
        'topicTitle': data['topic_title'],
        'executionId': data['execution_id'],
      })).toList();
    } catch (e) {
      debugPrint('Get User Performance Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTopicPerformance(String userId, String topicTitle) async {
    try {
      final response = await client
          .from('question_results')
          .select()
          .eq('user_id', userId)
          .eq('topic_title', topicTitle);

      final results = response.map<QuestionResult>((data) => QuestionResult.fromJson({
        'questionText': data['question_text'],
        'userAnswer': data['user_answer'],
        'isCorrect': data['is_correct'],
        'timestamp': data['timestamp'],
        'topicTitle': data['topic_title'],
        'executionId': data['execution_id'],
      })).toList();

      final totalQuestions = results.length;
      final correctAnswers = results.where((r) => r.isCorrect).length;
      final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

      return {
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'wrongAnswers': totalQuestions - correctAnswers,
        'accuracyPercentage': accuracy,
        'results': results,
      };
    } catch (e) {
      debugPrint('Get Topic Performance Error: $e');
      return {
        'totalQuestions': 0,
        'correctAnswers': 0,
        'wrongAnswers': 0,
        'accuracyPercentage': 0.0,
        'results': <QuestionResult>[],
      };
    }
  }

  // Utility Methods
  String? getCurrentUserId() {
    return client.auth.currentUser?.id;
  }

  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  bool get isAuthenticated => client.auth.currentUser != null;

  // Real-time subscriptions
  RealtimeChannel subscribeToUserSessions(String userId, Function(List<ChatSession>) onUpdate) {
    return client
        .channel('user_sessions_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final sessions = await getUserChatSessions(userId);
            onUpdate(sessions);
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToUserPerformance(String userId, Function(List<QuestionResult>) onUpdate) {
    return client
        .channel('user_performance_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'question_results',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final performance = await getUserPerformance(userId);
            onUpdate(performance);
          },
        )
        .subscribe();
  }
}