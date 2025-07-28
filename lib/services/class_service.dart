import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/class_model.dart';
import 'supabase_service.dart';

class ClassService extends ChangeNotifier {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  List<ClassModel> _teacherClasses = [];
  List<ClassModel> _studentClasses = [];
  final List<ClassEnrollment> _classEnrollments = [];
  bool _isLoading = false;

  List<ClassModel> get teacherClasses => _teacherClasses;
  List<ClassModel> get studentClasses => _studentClasses;
  List<ClassEnrollment> get classEnrollments => _classEnrollments;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Teacher CRUD Operations

  /// Create a new class (Teachers only)
  Future<ClassModel?> createClass(CreateClassRequest request) async {
    try {
      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('classes')
          .insert({
            'teacher_id': userId,
            'name': request.name,
            'description': request.description,
            'subject': request.subject,
            'grade_level': request.gradeLevel,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final newClass = ClassModel.fromJson(response);
      _teacherClasses.insert(0, newClass);
      notifyListeners();

      return newClass;
    } catch (e) {
      debugPrint('Create Class Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get all classes for a teacher
  Future<List<ClassModel>> getTeacherClasses({bool refresh = false}) async {
    try {
      if (!refresh && _teacherClasses.isNotEmpty) {
        return _teacherClasses;
      }

      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('classes')
          .select('''
            *,
            class_enrollments!inner(count)
          ''')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _teacherClasses = response.map<ClassModel>((data) {
        final enrollmentCount = data['class_enrollments'] as List? ?? [];
        return ClassModel.fromJson({
          ...data,
          'enrolled_students_count': enrollmentCount.length,
        });
      }).toList();

      notifyListeners();
      return _teacherClasses;
    } catch (e) {
      debugPrint('Get Teacher Classes Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get all classes a student is enrolled in
  Future<List<ClassModel>> getStudentClasses({bool refresh = false}) async {
    try {
      if (!refresh && _studentClasses.isNotEmpty) {
        return _studentClasses;
      }

      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('class_enrollments')
          .select('''
            classes!inner(*,
              user_profiles!classes_teacher_id_fkey(full_name)
            )
          ''')
          .eq('student_id', userId)
          .eq('is_active', true)
          .eq('classes.is_active', true)
          .order('enrolled_at', ascending: false);

      _studentClasses = response.map<ClassModel>((data) {
        final classData = data['classes'];
        final teacherProfile = classData['user_profiles'];
        return ClassModel.fromJson({
          ...classData,
          'teacher_name': teacherProfile?['full_name'],
        });
      }).toList();

      notifyListeners();
      return _studentClasses;
    } catch (e) {
      debugPrint('Get Student Classes Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final response = await _client.from('classes').select('''
            *,
            user_profiles!classes_teacher_id_fkey(full_name),
            class_enrollments(count)
          ''').eq('id', classId).single();

      final teacherProfile = response['user_profiles'];
      final enrollments = response['class_enrollments'] as List? ?? [];

      return ClassModel.fromJson({
        ...response,
        'teacher_name': teacherProfile?['full_name'],
        'enrolled_students_count': enrollments.length,
      });
    } catch (e) {
      debugPrint('Get Class By ID Error: $e');
      return null;
    }
  }

  /// Update a class (Teachers only)
  Future<ClassModel?> updateClass(
      String classId, UpdateClassRequest request) async {
    try {
      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('classes')
          .update(request.toJson())
          .eq('id', classId)
          .eq('teacher_id', userId)
          .select()
          .single();

      final updatedClass = ClassModel.fromJson(response);

      // Update local cache
      final index = _teacherClasses.indexWhere((c) => c.id == classId);
      if (index != -1) {
        _teacherClasses[index] = updatedClass;
        notifyListeners();
      }

      return updatedClass;
    } catch (e) {
      debugPrint('Update Class Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a class (Teachers only)
  Future<bool> deleteClass(String classId) async {
    try {
      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('classes')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', classId)
          .eq('teacher_id', userId);

      // Remove from local cache
      _teacherClasses.removeWhere((c) => c.id == classId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Delete Class Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Student Operations

  /// Join a class using class code (Students only)
  Future<JoinClassResult> joinClassByCode(String classCode) async {
    try {
      _setLoading(true);

      final response = await _client.rpc('join_class_by_code', params: {
        'p_class_code': classCode.toUpperCase(),
      });

      final result = JoinClassResult.fromJson(response);

      if (result.success) {
        // Refresh student classes to include the new enrollment
        await getStudentClasses(refresh: true);
      }

      return result;
    } catch (e) {
      debugPrint('Join Class Error: $e');
      return JoinClassResult(
        success: false,
        error: 'Failed to join class: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Leave a class (Students only)
  Future<bool> leaveClass(String classId) async {
    try {
      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('class_enrollments')
          .update({'is_active': false})
          .eq('class_id', classId)
          .eq('student_id', userId);

      // Remove from local cache
      _studentClasses.removeWhere((c) => c.id == classId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Leave Class Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Class Enrollment Management

  /// Get all students enrolled in a class (Teachers only)
  Future<List<ClassEnrollment>> getClassEnrollments(String classId) async {
    try {
      final response = await _client
          .from('class_enrollments')
          .select('''
            *,
            user_profiles!class_enrollments_student_id_fkey(
              full_name,
              email,
              grade
            )
          ''')
          .eq('class_id', classId)
          .eq('is_active', true)
          .order('enrolled_at', ascending: false);

      return response.map<ClassEnrollment>((data) {
        final studentProfile = data['user_profiles'];
        return ClassEnrollment.fromJson({
          ...data,
          'student_name': studentProfile?['full_name'],
          'student_email': studentProfile?['email'],
          'student_grade': studentProfile?['grade'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Get Class Enrollments Error: $e');
      return [];
    }
  }

  /// Remove a student from class (Teachers only)
  Future<bool> removeStudentFromClass(String classId, String studentId) async {
    try {
      _setLoading(true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Verify teacher owns this class
      final classExists = await _client
          .from('classes')
          .select('id')
          .eq('id', classId)
          .eq('teacher_id', userId)
          .maybeSingle();

      if (classExists == null) {
        throw Exception('Class not found or access denied');
      }

      await _client
          .from('class_enrollments')
          .update({'is_active': false})
          .eq('class_id', classId)
          .eq('student_id', studentId);

      return true;
    } catch (e) {
      debugPrint('Remove Student Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Real-time subscriptions

  /// Subscribe to class updates for a teacher
  RealtimeChannel subscribeToTeacherClasses(String teacherId) {
    return _client
        .channel('teacher_classes_$teacherId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'classes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_id',
            value: teacherId,
          ),
          callback: (payload) {
            getTeacherClasses(refresh: true);
          },
        )
        .subscribe();
  }

  /// Subscribe to enrollment changes for a class
  RealtimeChannel subscribeToClassEnrollments(String classId) {
    return _client
        .channel('class_enrollments_$classId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'class_enrollments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'class_id',
            value: classId,
          ),
          callback: (payload) {
            // Refresh enrollments for this class
            notifyListeners();
          },
        )
        .subscribe();
  }

  /// Subscribe to student class changes
  RealtimeChannel subscribeToStudentClasses(String studentId) {
    return _client
        .channel('student_classes_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'class_enrollments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            getStudentClasses(refresh: true);
          },
        )
        .subscribe();
  }

  // Utility methods

  /// Clear all cached data
  void clearCache() {
    _teacherClasses.clear();
    _studentClasses.clear();
    _classEnrollments.clear();
    notifyListeners();
  }

  /// Check if user is enrolled in a specific class
  bool isEnrolledInClass(String classId) {
    return _studentClasses.any((c) => c.id == classId);
  }

  /// Get class by code (for validation)
  Future<ClassModel?> getClassByCode(String classCode) async {
    try {
      final response = await _client
          .from('classes')
          .select('''
            *,
            user_profiles!classes_teacher_id_fkey(full_name)
          ''')
          .eq('class_code', classCode.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final teacherProfile = response['user_profiles'];
      return ClassModel.fromJson({
        ...response,
        'teacher_name': teacherProfile?['full_name'],
      });
    } catch (e) {
      debugPrint('Get Class By Code Error: $e');
      return null;
    }
  }
}
