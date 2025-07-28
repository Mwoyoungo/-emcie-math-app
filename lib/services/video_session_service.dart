import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/video_session_model.dart';
import 'supabase_service.dart';

class VideoSessionService extends ChangeNotifier {
  static final VideoSessionService _instance = VideoSessionService._internal();
  factory VideoSessionService() => _instance;
  VideoSessionService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get _client => _supabaseService.client;

  List<VideoSession> _teacherSessions = [];
  List<VideoSessionInstance> _upcomingInstances = [];
  List<VideoSessionInstance> _studentSessions = [];
  bool _isLoading = false;

  List<VideoSession> get teacherSessions => _teacherSessions;
  List<VideoSessionInstance> get upcomingInstances => _upcomingInstances;
  List<VideoSessionInstance> get studentSessions => _studentSessions;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Generate unique channel name
  String _generateChannelName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'session_$random';
  }

  /// Create a new video session (Teachers only)
  Future<VideoSession?> createVideoSession(CreateVideoSessionRequest request) async {
    try {
      _setLoading(true);
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final channelName = _generateChannelName();

      final response = await _client
          .from('video_sessions')
          .insert({
            'class_id': request.classId,
            'teacher_id': userId,
            'title': request.title,
            'description': request.description,
            'duration_minutes': request.durationMinutes,
            'start_time': request.startTime,
            'recurring_days': request.recurringDays,
            'agora_channel_name': channelName,
            'video_link': request.videoLink,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            classes!inner(name)
          ''')
          .single();

      final responseMap = Map<String, dynamic>.from(response);
      final classData = Map<String, dynamic>.from(responseMap['classes']);
      
      final newSession = VideoSession.fromJson({
        ...responseMap,
        'class_name': classData['name'],
      });

      _teacherSessions.insert(0, newSession);
      notifyListeners();
      
      return newSession;
    } catch (e) {
      debugPrint('Create Video Session Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get all video sessions for a teacher
  Future<List<VideoSession>> getTeacherVideoSessions({bool refresh = false}) async {
    try {
      if (!refresh && _teacherSessions.isNotEmpty) {
        return _teacherSessions;
      }

      _setLoading(true);
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('video_sessions')
          .select('''
            *,
            classes!inner(name)
          ''')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _teacherSessions = response.map<VideoSession>((data) {
        final dataMap = Map<String, dynamic>.from(data);
        final classData = Map<String, dynamic>.from(dataMap['classes']);
        
        return VideoSession.fromJson({
          ...dataMap,
          'class_name': classData['name'],
        });
      }).toList();

      notifyListeners();
      return _teacherSessions;
    } catch (e) {
      debugPrint('Get Teacher Video Sessions Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get video sessions for a specific class
  Future<List<VideoSession>> getClassVideoSessions(String classId) async {
    try {
      final response = await _client
          .from('video_sessions')
          .select('''
            *,
            classes!inner(name),
            user_profiles!video_sessions_teacher_id_fkey(full_name)
          ''')
          .eq('class_id', classId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map<VideoSession>((data) {
        final dataMap = Map<String, dynamic>.from(data);
        final classData = Map<String, dynamic>.from(dataMap['classes']);
        final profileData = Map<String, dynamic>.from(dataMap['user_profiles']);
        
        return VideoSession.fromJson({
          ...dataMap,
          'class_name': classData['name'],
          'teacher_name': profileData['full_name'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Get Class Video Sessions Error: $e');
      return [];
    }
  }

  /// Get upcoming session instances for a teacher
  Future<List<VideoSessionInstance>> getUpcomingSessionInstances({bool refresh = false}) async {
    try {
      if (!refresh && _upcomingInstances.isNotEmpty) {
        return _upcomingInstances;
      }

      _setLoading(true);
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final response = await _client
          .from('video_session_instances')
          .select('''
            *,
            video_sessions!inner(*,
              classes!inner(name)
            )
          ''')
          .eq('video_sessions.teacher_id', userId)
          .gte('scheduled_date', startOfToday.toIso8601String().split('T')[0])
          .inFilter('status', ['scheduled', 'ongoing'])
          .order('scheduled_start_time', ascending: true)
          .limit(20);

      _upcomingInstances = response.map<VideoSessionInstance>((data) {
        final dataMap = Map<String, dynamic>.from(data);
        final videoSessionData = Map<String, dynamic>.from(dataMap['video_sessions']);
        final classData = Map<String, dynamic>.from(videoSessionData['classes']);
        
        return VideoSessionInstance.fromJson({
          ...dataMap,
          'video_sessions': {
            ...videoSessionData,
            'class_name': classData['name'],
          },
        });
      }).toList();

      notifyListeners();
      return _upcomingInstances;
    } catch (e) {
      debugPrint('Get Upcoming Session Instances Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get student's upcoming sessions
  Future<List<VideoSessionInstance>> getStudentUpcomingSessions({bool refresh = false}) async {
    try {
      if (!refresh && _studentSessions.isNotEmpty) {
        return _studentSessions;
      }

      _setLoading(true);
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      // Get sessions for classes the student is enrolled in
      final response = await _client
          .from('video_session_instances')
          .select('''
            *,
            video_sessions!inner(*,
              classes!inner(name,
                class_enrollments!inner(student_id)
              )
            )
          ''')
          .eq('video_sessions.classes.class_enrollments.student_id', userId)
          .eq('video_sessions.classes.class_enrollments.is_active', true)
          .gte('scheduled_date', startOfToday.toIso8601String().split('T')[0])
          .inFilter('status', ['scheduled', 'ongoing'])
          .order('scheduled_start_time', ascending: true)
          .limit(20);

      _studentSessions = response.map<VideoSessionInstance>((data) {
        final dataMap = Map<String, dynamic>.from(data);
        final videoSessionData = Map<String, dynamic>.from(dataMap['video_sessions']);
        final classData = Map<String, dynamic>.from(videoSessionData['classes']);
        
        return VideoSessionInstance.fromJson({
          ...dataMap,
          'video_sessions': {
            ...videoSessionData,
            'class_name': classData['name'],
          },
        });
      }).toList();

      notifyListeners();
      return _studentSessions;
    } catch (e) {
      debugPrint('Get Student Upcoming Sessions Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Update a video session (Teachers only)
  Future<VideoSession?> updateVideoSession(String sessionId, UpdateVideoSessionRequest request) async {
    try {
      _setLoading(true);
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('video_sessions')
          .update(request.toJson())
          .eq('id', sessionId)
          .eq('teacher_id', userId)
          .select('''
            *,
            classes!inner(name)
          ''')
          .single();

      final responseMap = Map<String, dynamic>.from(response);
      final classData = Map<String, dynamic>.from(responseMap['classes']);
      
      final updatedSession = VideoSession.fromJson({
        ...responseMap,
        'class_name': classData['name'],
      });
      
      // Update local cache
      final index = _teacherSessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _teacherSessions[index] = updatedSession;
        notifyListeners();
      }
      
      return updatedSession;
    } catch (e) {
      debugPrint('Update Video Session Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a video session (Teachers only)
  Future<bool> deleteVideoSession(String sessionId) async {
    try {
      _setLoading(true);
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('video_sessions')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', sessionId)
          .eq('teacher_id', userId);

      // Remove from local cache
      _teacherSessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Delete Video Session Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start a session instance
  Future<bool> startSessionInstance(String instanceId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('video_session_instances')
          .update({
            'status': 'ongoing',
            'actual_start_time': DateTime.now().toIso8601String(),
          })
          .eq('id', instanceId);

      // Refresh data
      await getUpcomingSessionInstances(refresh: true);
      
      return true;
    } catch (e) {
      debugPrint('Start Session Instance Error: $e');
      return false;
    }
  }

  /// End a session instance
  Future<bool> endSessionInstance(String instanceId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('video_session_instances')
          .update({
            'status': 'completed',
            'actual_end_time': DateTime.now().toIso8601String(),
          })
          .eq('id', instanceId);

      // Refresh data
      await getUpcomingSessionInstances(refresh: true);
      
      return true;
    } catch (e) {
      debugPrint('End Session Instance Error: $e');
      return false;
    }
  }

  /// Join a session (Students)
  Future<bool> joinSession(String instanceId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Record attendance
      await _client
          .from('video_session_attendance')
          .upsert({
            'session_instance_id': instanceId,
            'student_id': userId,
            'joined_at': DateTime.now().toIso8601String(),
            'is_present': true,
          });

      return true;
    } catch (e) {
      debugPrint('Join Session Error: $e');
      return false;
    }
  }

  /// Record student joining session (alias for joinSession)
  Future<bool> recordStudentJoin(String instanceId) async {
    return await joinSession(instanceId);
  }

  /// Leave a session (Students)
  Future<bool> leaveSession(String instanceId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get current attendance record
      final attendance = await _client
          .from('video_session_attendance')
          .select()
          .eq('session_instance_id', instanceId)
          .eq('student_id', userId)
          .maybeSingle();

      if (attendance != null) {
        final joinedAt = DateTime.parse(attendance['joined_at'] as String);
        final leftAt = DateTime.now();
        final durationMinutes = leftAt.difference(joinedAt).inMinutes;

        await _client
            .from('video_session_attendance')
            .update({
              'left_at': leftAt.toIso8601String(),
              'total_duration_minutes': durationMinutes,
            })
            .eq('id', attendance['id']);
      }

      return true;
    } catch (e) {
      debugPrint('Leave Session Error: $e');
      return false;
    }
  }

  /// Get session attendance
  Future<List<VideoSessionAttendance>> getSessionAttendance(String instanceId) async {
    try {
      final response = await _client
          .from('video_session_attendance')
          .select('''
            *,
            user_profiles!video_session_attendance_student_id_fkey(
              full_name,
              email
            )
          ''')
          .eq('session_instance_id', instanceId)
          .order('joined_at', ascending: false);

      return response.map<VideoSessionAttendance>((data) {
        final dataMap = Map<String, dynamic>.from(data);
        final studentProfile = dataMap['user_profiles'] != null 
          ? Map<String, dynamic>.from(dataMap['user_profiles'])
          : null;
          
        return VideoSessionAttendance.fromJson({
          ...dataMap,
          'student_name': studentProfile?['full_name'],
          'student_email': studentProfile?['email'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Get Session Attendance Error: $e');
      return [];
    }
  }

  /// Get session instance by ID
  Future<VideoSessionInstance?> getSessionInstance(String instanceId) async {
    try {
      final response = await _client
          .from('video_session_instances')
          .select('''
            *,
            video_sessions!inner(*,
              classes!inner(name),
              user_profiles!video_sessions_teacher_id_fkey(full_name)
            )
          ''')
          .eq('id', instanceId)
          .single();

      final responseMap = Map<String, dynamic>.from(response);
      final videoSessionData = Map<String, dynamic>.from(responseMap['video_sessions']);
      final classData = Map<String, dynamic>.from(videoSessionData['classes']);
      final profileData = Map<String, dynamic>.from(videoSessionData['user_profiles']);
      
      return VideoSessionInstance.fromJson({
        ...responseMap,
        'video_sessions': {
          ...videoSessionData,
          'class_name': classData['name'],
          'teacher_name': profileData['full_name'],
        },
      });
    } catch (e) {
      debugPrint('Get Session Instance Error: $e');
      return null;
    }
  }

  /// Check if student can join session
  Future<bool> canStudentJoinSession(String instanceId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if student is enrolled in the class for this session
      final response = await _client
          .from('video_session_instances')
          .select('''
            video_sessions!inner(
              class_id,
              classes!inner(
                class_enrollments!inner(student_id, is_active)
              )
            )
          ''')
          .eq('id', instanceId)
          .eq('video_sessions.classes.class_enrollments.student_id', userId)
          .eq('video_sessions.classes.class_enrollments.is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Can Student Join Session Error: $e');
      return false;
    }
  }

  /// Generate session instances for next 4 weeks
  Future<void> generateSessionInstances(String sessionId) async {
    try {
      await _client.rpc('generate_session_instances', params: {
        'p_video_session_id': sessionId,
      });
    } catch (e) {
      debugPrint('Generate Session Instances Error: $e');
    }
  }

  /// Real-time subscriptions

  /// Subscribe to teacher's video sessions
  RealtimeChannel subscribeToTeacherSessions(String teacherId) {
    return _client
        .channel('teacher_video_sessions_$teacherId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'video_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_id',
            value: teacherId,
          ),
          callback: (payload) {
            getTeacherVideoSessions(refresh: true);
          },
        )
        .subscribe();
  }

  /// Subscribe to session instances
  RealtimeChannel subscribeToSessionInstances() {
    return _client
        .channel('video_session_instances')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'video_session_instances',
          callback: (payload) {
            getUpcomingSessionInstances(refresh: true);
            getStudentUpcomingSessions(refresh: true);
          },
        )
        .subscribe();
  }

  /// Clear all cached data
  void clearCache() {
    _teacherSessions.clear();
    _upcomingInstances.clear();
    _studentSessions.clear();
    notifyListeners();
  }

  /// Format time for display
  static String formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  /// Parse time from display format
  static String parseTime(String displayTime) {
    try {
      final regex = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
      final match = regex.firstMatch(displayTime);
      
      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)!.toUpperCase();
        
        int hour24 = hour;
        if (period == 'PM' && hour != 12) {
          hour24 += 12;
        } else if (period == 'AM' && hour == 12) {
          hour24 = 0;
        }
        
        return '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      debugPrint('Parse time error: $e');
    }
    return displayTime;
  }
}