import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Class Model
class SchoolClass {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final String subject;
  final String? gradeLevel;
  final String classCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? enrolledCount;

  SchoolClass({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.subject,
    this.gradeLevel,
    required this.classCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.enrolledCount,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      subject: map['subject'] ?? 'Mathematics',
      gradeLevel: map['grade_level'],
      classCode: map['class_code'] ?? '',
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      enrolledCount: map['enrolled_count'],
    );
  }
}

// Class Enrollment Model
class ClassEnrollment {
  final String id;
  final String classId;
  final String studentId;
  final DateTime enrolledAt;
  final bool isActive;
  // Additional fields from joined data
  final String? className;
  final String? teacherName;
  final String? studentName;

  ClassEnrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.enrolledAt,
    required this.isActive,
    this.className,
    this.teacherName,
    this.studentName,
  });

  factory ClassEnrollment.fromMap(Map<String, dynamic> map) {
    return ClassEnrollment(
      id: map['id'] ?? '',
      classId: map['class_id'] ?? '',
      studentId: map['student_id'] ?? '',
      enrolledAt: DateTime.parse(map['enrolled_at']),
      isActive: map['is_active'] ?? true,
      className: map['class_name'],
      teacherName: map['teacher_name'],
      studentName: map['student_name'],
    );
  }
}

// Class Service
class ClassService extends ChangeNotifier {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();
  
  static ClassService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<SchoolClass> _teacherClasses = [];
  List<ClassEnrollment> _studentEnrollments = [];
  bool _isLoading = false;

  // Getters
  List<SchoolClass> get teacherClasses => _teacherClasses;
  List<ClassEnrollment> get studentEnrollments => _studentEnrollments;
  bool get isLoading => _isLoading;

  // Teacher Methods
  Future<List<SchoolClass>> fetchTeacherClasses() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('classes')
          .select('''
            *,
            enrolled_count:class_enrollments(count)
          ''')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _teacherClasses = (response as List).map((data) {
        // Handle the count from the nested query
        final enrolledCount = data['enrolled_count'] is List 
          ? (data['enrolled_count'] as List).length 
          : 0;
        
        return SchoolClass.fromMap({
          ...data,
          'enrolled_count': enrolledCount,
        });
      }).toList();

      return _teacherClasses;
    } catch (e) {
      debugPrint('Error fetching teacher classes: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SchoolClass> createClass({
    required String name,
    String? description,
    String subject = 'Mathematics', 
    String? gradeLevel,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('classes')
          .insert({
            'teacher_id': userId,
            'name': name.trim(),
            'description': description?.trim(),
            'subject': subject,
            'grade_level': gradeLevel?.trim(),
          })
          .select()
          .single();

      final newClass = SchoolClass.fromMap(response);
      _teacherClasses.insert(0, newClass);
      notifyListeners();

      return newClass;
    } catch (e) {
      debugPrint('Error creating class: $e');
      rethrow;
    }
  }

  Future<void> updateClass(
    String classId, {
    String? name,
    String? description, 
    String? subject,
    String? gradeLevel,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (description != null) updates['description'] = description.trim();
      if (subject != null) updates['subject'] = subject;
      if (gradeLevel != null) updates['grade_level'] = gradeLevel.trim();
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase
          .from('classes')
          .update(updates)
          .eq('id', classId);

      // Refresh classes
      await fetchTeacherClasses();
    } catch (e) {
      debugPrint('Error updating class: $e');
      rethrow;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      await _supabase
          .from('classes')
          .update({'is_active': false})
          .eq('id', classId);

      _teacherClasses.removeWhere((c) => c.id == classId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting class: $e');
      rethrow;
    }
  }

  // Student Methods
  Future<List<ClassEnrollment>> fetchStudentEnrollments() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('class_enrollments')
          .select('''
            *,
            classes!inner(name, subject, grade_level, teacher_id),
            teacher:classes(teacher_id, user_profiles!inner(full_name))
          ''')
          .eq('student_id', userId)
          .eq('is_active', true)
          .order('enrolled_at', ascending: false);

      _studentEnrollments = (response as List).map((data) {
        final classData = data['classes'];
        final teacherData = data['teacher']?['user_profiles'];
        
        return ClassEnrollment.fromMap({
          ...data,
          'class_name': classData?['name'],
          'teacher_name': teacherData?['full_name'],
        });
      }).toList();

      return _studentEnrollments;
    } catch (e) {
      debugPrint('Error fetching student enrollments: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> joinClassByCode(String classCode) async {
    try {
      final response = await _supabase
          .rpc('join_class_by_code', params: {'p_class_code': classCode.trim().toUpperCase()});

      final result = response as Map<String, dynamic>;
      
      if (result['success'] == true) {
        // Refresh enrollments
        await fetchStudentEnrollments();
      }
      
      return result;
    } catch (e) {
      debugPrint('Error joining class: $e');
      return {'success': false, 'error': 'Failed to join class: $e'};
    }
  }

  Future<void> leaveClass(String enrollmentId) async {
    try {
      await _supabase
          .from('class_enrollments')
          .update({'is_active': false})
          .eq('id', enrollmentId);

      _studentEnrollments.removeWhere((e) => e.id == enrollmentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving class: $e');
      rethrow;
    }
  }

  // Get class enrollments for teachers
  Future<List<ClassEnrollment>> getClassStudents(String classId) async {
    try {
      final response = await _supabase
          .from('class_enrollments')
          .select('''
            *,
            student:user_profiles!inner(full_name, email, grade)
          ''')
          .eq('class_id', classId)
          .eq('is_active', true)
          .order('enrolled_at', ascending: false);

      return (response as List).map((data) {
        final studentData = data['student'];
        
        return ClassEnrollment.fromMap({
          ...data,
          'student_name': studentData?['full_name'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching class students: $e');
      rethrow;
    }
  }
}