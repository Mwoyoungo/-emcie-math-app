import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_session_service.dart';

class SharedChat {
  final String id;
  final String studentId;
  final String teacherId;
  final String? classId;
  final String topicTitle;
  final String studentName;
  final String className;
  final ChatSession chatSession;
  final DateTime sharedAt;
  final String? message;
  final bool isRead;

  SharedChat({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.classId,
    required this.topicTitle,
    required this.studentName,
    required this.className,
    required this.chatSession,
    required this.sharedAt,
    this.message,
    required this.isRead,
  });

  factory SharedChat.fromMap(Map<String, dynamic> map) {
    return SharedChat(
      id: map['id'] ?? '',
      studentId: map['student_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      classId: map['class_id'],
      topicTitle: map['topic_title'] ?? '',
      studentName: map['student_name'] ?? '',
      className: map['class_name'] ?? '',
      chatSession: ChatSession.fromJson(map['chat_data']),
      sharedAt: DateTime.parse(map['shared_at']),
      message: map['message'],
      isRead: map['is_read'] ?? false,
    );
  }
}

class ChatSharingService extends ChangeNotifier {
  static final ChatSharingService _instance = ChatSharingService._internal();
  factory ChatSharingService() => _instance;
  ChatSharingService._internal();

  static ChatSharingService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  List<SharedChat> _teacherSharedChats = [];
  bool _isLoading = false;

  List<SharedChat> get teacherSharedChats => _teacherSharedChats;
  bool get isLoading => _isLoading;

  // Student shares a chat with their teacher
  Future<bool> shareChat({
    required String classId,
    required ChatSession chatSession,
    String? message,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get teacher ID and class name from class
      final classResponse = await _supabase
          .from('classes')
          .select('teacher_id, name')
          .eq('id', classId)
          .single();

      final teacherId = classResponse['teacher_id'];
      final className = classResponse['name'];

      // Get student name
      final studentResponse = await _supabase
          .from('user_profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      final studentName = studentResponse['full_name'];

      // Create shared chat record with all required fields
      final topicTitle = chatSession.topicTitle.isEmpty ? 'Untitled Chat' : chatSession.topicTitle;
      
      debugPrint('Sharing chat with data:');
      debugPrint('  student_id: $userId');
      debugPrint('  teacher_id: $teacherId');
      debugPrint('  class_id: $classId');
      debugPrint('  topic_title: $topicTitle');
      debugPrint('  student_name: $studentName');
      debugPrint('  class_name: $className');
      debugPrint('  message: $message');
      
      await _supabase.from('shared_chats').insert({
        'student_id': userId,
        'teacher_id': teacherId,
        'class_id': classId,
        'topic_title': topicTitle,
        'student_name': studentName,
        'class_name': className,
        'chat_data': chatSession.toJson(),
        'message': message,
        'is_read': false,
      });

      debugPrint('Chat shared successfully with teacher');
      return true;
    } catch (e) {
      debugPrint('Error sharing chat: $e');
      return false;
    }
  }

  // Teacher fetches shared chats from students
  Future<List<SharedChat>> fetchTeacherSharedChats() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('shared_chats')
          .select('*')
          .eq('teacher_id', userId)
          .order('shared_at', ascending: false);

      _teacherSharedChats = (response as List)
          .map((data) => SharedChat.fromMap(data))
          .toList();

      return _teacherSharedChats;
    } catch (e) {
      debugPrint('Error fetching shared chats: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get unread count for teacher (simplified - all chats are considered "unread")
  int get unreadCount => _teacherSharedChats.length;

  // Delete shared chat
  Future<void> deleteSharedChat(String sharedChatId) async {
    try {
      await _supabase
          .from('shared_chats')
          .delete()
          .eq('id', sharedChatId);

      _teacherSharedChats.removeWhere((chat) => chat.id == sharedChatId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting shared chat: $e');
      rethrow;
    }
  }

  // Get student's classes for sharing options
  Future<List<Map<String, dynamic>>> getStudentClasses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('class_enrollments')
          .select('''
            class_id,
            classes!inner(id, name, teacher_id)
          ''')
          .eq('student_id', userId)
          .eq('is_active', true);

      // Get teacher names separately
      final List<Map<String, dynamic>> result = [];
      for (final enrollment in response as List) {
        final classData = enrollment['classes'];
        final teacherId = classData?['teacher_id'];
        
        // Get teacher name
        String teacherName = 'Unknown Teacher';
        if (teacherId != null) {
          try {
            final teacherResponse = await _supabase
                .from('user_profiles')
                .select('full_name')
                .eq('id', teacherId)
                .single();
            teacherName = teacherResponse['full_name'] ?? 'Unknown Teacher';
          } catch (e) {
            debugPrint('Error fetching teacher name: $e');
          }
        }
        
        result.add({
          'class_id': enrollment['class_id'],
          'class_name': classData?['name'] ?? 'Unknown Class',
          'teacher_name': teacherName,
        });
      }
      
      return result;
    } catch (e) {
      debugPrint('Error fetching student classes: $e');
      return [];
    }
  }
}