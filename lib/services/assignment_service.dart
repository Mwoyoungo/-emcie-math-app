import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class Assignment {
  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final int maxFileSizeMb;
  final List<String> allowedFileTypes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.maxFileSizeMb,
    required this.allowedFileTypes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] ?? '',
      classId: map['class_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      dueDate: DateTime.parse(map['due_date']),
      maxFileSizeMb: map['max_file_size_mb'] ?? 10,
      allowedFileTypes: List<String>.from(map['allowed_file_types'] ?? ['pdf', 'png', 'jpg', 'jpeg']),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate);
  }

  Duration get timeUntilDue {
    return dueDate.difference(DateTime.now());
  }

  String get dueDateFormatted {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return '${difference.inMinutes} minutes left';
    }
  }
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String fileUrl;
  final String fileName;
  final int fileSizeBytes;
  final String fileType;
  final DateTime submittedAt;
  final double? grade; // 0-100
  final String? teacherFeedback;
  final DateTime? gradedAt;
  final String? gradedBy;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileUrl,
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileType,
    required this.submittedAt,
    this.grade,
    this.teacherFeedback,
    this.gradedAt,
    this.gradedBy,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id'] ?? '',
      assignmentId: map['assignment_id'] ?? '',
      studentId: map['student_id'] ?? '',
      fileUrl: map['file_url'] ?? '',
      fileName: map['file_name'] ?? '',
      fileSizeBytes: map['file_size_bytes'] ?? 0,
      fileType: map['file_type'] ?? '',
      submittedAt: DateTime.parse(map['submitted_at']),
      grade: map['grade']?.toDouble(),
      teacherFeedback: map['teacher_feedback'],
      gradedAt: map['graded_at'] != null ? DateTime.parse(map['graded_at']) : null,
      gradedBy: map['graded_by'],
    );
  }

  bool get isGraded => grade != null;

  String get gradeDisplay {
    if (grade == null) return 'Not graded';
    return '${grade!.toStringAsFixed(1)}%';
  }

  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class AssignmentSubmissionSummary {
  final String studentId;
  final String studentName;
  final AssignmentSubmission? submission;
  final bool hasSubmitted;

  AssignmentSubmissionSummary({
    required this.studentId,
    required this.studentName,
    this.submission,
    required this.hasSubmitted,
  });
}

class AssignmentService extends ChangeNotifier {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  static AssignmentService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Assignment> _teacherAssignments = [];
  List<Assignment> _studentAssignments = [];
  List<AssignmentSubmission> _studentSubmissions = [];
  bool _isLoading = false;

  List<Assignment> get teacherAssignments => _teacherAssignments;
  List<Assignment> get studentAssignments => _studentAssignments;
  List<AssignmentSubmission> get studentSubmissions => _studentSubmissions;
  bool get isLoading => _isLoading;

  // Create a new assignment
  Future<Assignment?> createAssignment({
    required String classId,
    required String title,
    String? description,
    required DateTime dueDate,
    int maxFileSizeMb = 10,
    List<String> allowedFileTypes = const ['pdf', 'png', 'jpg', 'jpeg'],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.from('assignments').insert({
        'class_id': classId,
        'teacher_id': userId,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'max_file_size_mb': maxFileSizeMb,
        'allowed_file_types': allowedFileTypes,
      }).select().single();

      final assignment = Assignment.fromMap(response);
      _teacherAssignments.add(assignment);
      notifyListeners();

      debugPrint('Assignment created: ${assignment.id}');
      return assignment;
    } catch (e) {
      debugPrint('Error creating assignment: $e');
      return null;
    }
  }

  // Fetch teacher's assignments
  Future<List<Assignment>> fetchTeacherAssignments() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('assignments')
          .select('*')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _teacherAssignments = (response as List)
          .map((data) => Assignment.fromMap(data))
          .toList();

      return _teacherAssignments;
    } catch (e) {
      debugPrint('Error fetching teacher assignments: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch student's assignments
  Future<List<Assignment>> fetchStudentAssignments() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get assignments for classes the student is enrolled in
      final response = await _supabase
          .from('assignments')
          .select('''
            *,
            classes!inner(
              class_enrollments!inner(student_id)
            )
          ''')
          .eq('classes.class_enrollments.student_id', userId)
          .eq('classes.class_enrollments.is_active', true)
          .eq('is_active', true)
          .order('due_date', ascending: true);

      _studentAssignments = (response as List)
          .map((data) => Assignment.fromMap(data))
          .toList();

      return _studentAssignments;
    } catch (e) {
      debugPrint('Error fetching student assignments: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit assignment with file upload
  Future<bool> submitAssignment({
    required String assignmentId,
    required PlatformFile file,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Validate file size and type
      final assignment = _studentAssignments.firstWhere(
        (a) => a.id == assignmentId,
        orElse: () => throw Exception('Assignment not found'),
      );

      if (file.size > assignment.maxFileSizeMb * 1024 * 1024) {
        throw Exception('File size exceeds ${assignment.maxFileSizeMb}MB limit');
      }

      final fileExtension = file.extension?.toLowerCase() ?? '';
      if (!assignment.allowedFileTypes.contains(fileExtension)) {
        throw Exception('File type not allowed. Allowed: ${assignment.allowedFileTypes.join(', ')}');
      }

      // Upload file to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'assignments/$assignmentId/$userId/$fileName';

      Uint8List fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('No file data available');
      }

      final uploadResponse = await _supabase.storage
          .from('assignment-files')
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final fileUrl = _supabase.storage
          .from('assignment-files')
          .getPublicUrl(filePath);

      // Create submission record
      await _supabase.from('assignment_submissions').insert({
        'assignment_id': assignmentId,
        'student_id': userId,
        'file_url': fileUrl,
        'file_name': file.name,
        'file_size_bytes': file.size,
        'file_type': fileExtension,
      });

      // Refresh student submissions
      await fetchStudentSubmissions();

      debugPrint('Assignment submitted successfully');
      return true;
    } catch (e) {
      debugPrint('Error submitting assignment: $e');
      return false;
    }
  }

  // Fetch student's submissions
  Future<List<AssignmentSubmission>> fetchStudentSubmissions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('assignment_submissions')
          .select('*')
          .eq('student_id', userId)
          .order('submitted_at', ascending: false);

      _studentSubmissions = (response as List)
          .map((data) => AssignmentSubmission.fromMap(data))
          .toList();

      return _studentSubmissions;
    } catch (e) {
      debugPrint('Error fetching student submissions: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Get assignment submission summary for teacher
  Future<List<AssignmentSubmissionSummary>> getAssignmentSubmissionSummary(String assignmentId) async {
    try {
      // Get all students enrolled in the class
      final assignment = _teacherAssignments.firstWhere(
        (a) => a.id == assignmentId,
        orElse: () => throw Exception('Assignment not found'),
      );

      final studentsResponse = await _supabase
          .from('class_enrollments')
          .select('''
            student_id,
            user_profiles!inner(id, full_name)
          ''')
          .eq('class_id', assignment.classId)
          .eq('is_active', true);

      // Get all submissions for this assignment
      final submissionsResponse = await _supabase
          .from('assignment_submissions')
          .select('*')
          .eq('assignment_id', assignmentId);

      final submissions = (submissionsResponse as List)
          .map((data) => AssignmentSubmission.fromMap(data))
          .toList();

      // Create summary for each student
      final summaries = <AssignmentSubmissionSummary>[];
      for (final student in studentsResponse as List) {
        final studentId = student['student_id'];
        final studentName = student['user_profiles']['full_name'] ?? 'Unknown';
        
        final submission = submissions.where(
          (s) => s.studentId == studentId,
        ).firstOrNull;

        summaries.add(AssignmentSubmissionSummary(
          studentId: studentId,
          studentName: studentName,
          submission: submission,
          hasSubmitted: submission != null,
        ));
      }

      return summaries;
    } catch (e) {
      debugPrint('Error getting assignment submission summary: $e');
      rethrow;
    }
  }

  // Grade assignment submission
  Future<bool> gradeSubmission({
    required String submissionId,
    required double grade,
    String? feedback,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('assignment_submissions')
          .update({
            'grade': grade,
            'teacher_feedback': feedback,
            'graded_at': DateTime.now().toIso8601String(),
            'graded_by': userId,
          })
          .eq('id', submissionId);

      debugPrint('Submission graded successfully');
      return true;
    } catch (e) {
      debugPrint('Error grading submission: $e');
      return false;
    }
  }

  // Get assignments for a specific class
  Future<List<Assignment>> getClassAssignments(String classId) async {
    try {
      final response = await _supabase
          .from('assignments')
          .select('*')
          .eq('class_id', classId)
          .eq('is_active', true)
          .order('due_date', ascending: true);

      return (response as List)
          .map((data) => Assignment.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching class assignments: $e');
      rethrow;
    }
  }

  // Check if student has submitted assignment
  Future<AssignmentSubmission?> getStudentSubmission(String assignmentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('assignment_submissions')
          .select('*')
          .eq('assignment_id', assignmentId)
          .eq('student_id', userId)
          .maybeSingle();

      if (response == null) return null;
      
      return AssignmentSubmission.fromMap(response);
    } catch (e) {
      debugPrint('Error checking student submission: $e');
      return null;
    }
  }

  // Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      await _supabase
          .from('assignments')
          .update({'is_active': false})
          .eq('id', assignmentId);

      _teacherAssignments.removeWhere((assignment) => assignment.id == assignmentId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      return false;
    }
  }

  // Update assignment
  Future<bool> updateAssignment({
    required String assignmentId,
    String? title,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();

      if (updates.isEmpty) return true;

      await _supabase
          .from('assignments')
          .update(updates)
          .eq('id', assignmentId);

      // Refresh teacher assignments
      await fetchTeacherAssignments();

      return true;
    } catch (e) {
      debugPrint('Error updating assignment: $e');
      return false;
    }
  }

  // Download file from URL
  Future<String?> downloadSubmissionFile(String fileUrl) async {
    try {
      // For web, we can just return the URL to open in new tab
      if (kIsWeb) {
        return fileUrl;
      }
      
      // For mobile/desktop, implement actual download
      // This would require additional platform-specific handling
      return fileUrl;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }
}