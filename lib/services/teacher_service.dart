import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Student Creation Request Model (keeping only teacher signup functionality)
class StudentCreationRequest {
  final String id;
  final String teacherId;
  final String studentEmail;
  final String studentFullName;
  final String studentGrade;
  final String status;
  final String? createdStudentId;
  final DateTime createdAt;
  final DateTime? processedAt;

  StudentCreationRequest({
    required this.id,
    required this.teacherId,
    required this.studentEmail,
    required this.studentFullName,
    required this.studentGrade,
    required this.status,
    this.createdStudentId,
    required this.createdAt,
    this.processedAt,
  });

  factory StudentCreationRequest.fromMap(Map<String, dynamic> map) {
    return StudentCreationRequest(
      id: map['id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      studentEmail: map['student_email'] ?? '',
      studentFullName: map['student_full_name'] ?? '',
      studentGrade: map['student_grade'] ?? '',
      status: map['status'] ?? 'pending',
      createdStudentId: map['created_student_id'],
      createdAt: DateTime.parse(map['created_at']),
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'])
          : null,
    );
  }
}

// Simplified Teacher Service Class - Only for teacher signup
class TeacherService extends ChangeNotifier {
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

  static TeacherService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  final bool _isLoading = false;

  // Getters
  bool get isLoading => _isLoading;

  // Student Creation Management (kept for teacher signup functionality)
  Future<StudentCreationRequest> createStudentAccount({
    required String studentEmail,
    required String studentFullName,
    required String studentGrade,
    required String temporaryPassword,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('student_creation_requests')
          .insert({
            'teacher_id': userId,
            'student_email': studentEmail,
            'student_full_name': studentFullName,
            'student_grade': studentGrade,
            'temporary_password': temporaryPassword, // This should be hashed
            'status': 'pending',
          })
          .select()
          .single();

      return StudentCreationRequest.fromMap(response);
    } catch (e) {
      debugPrint('Error creating student account request: $e');
      rethrow;
    }
  }

  Future<List<StudentCreationRequest>> fetchStudentCreationRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('student_creation_requests')
          .select()
          .eq('teacher_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => StudentCreationRequest.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching student creation requests: $e');
      rethrow;
    }
  }
}
