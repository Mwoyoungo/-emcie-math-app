import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart'; // Disabled for web compatibility

class VideoSession {
  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String? description;
  final int durationMinutes;
  final DateTime startTime; // Time of day as DateTime
  final List<int> recurringDays; // 1=Monday, 2=Tuesday, etc.
  final String agoraChannelName;
  final String? agoraAppId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoSession({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.startTime,
    required this.recurringDays,
    required this.agoraChannelName,
    this.agoraAppId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoSession.fromMap(Map<String, dynamic> map) {
    return VideoSession(
      id: map['id'] ?? '',
      classId: map['class_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      durationMinutes: map['duration_minutes'] ?? 0,
      startTime: _parseTimeFromString(map['start_time']),
      recurringDays: List<int>.from(map['recurring_days'] ?? []),
      agoraChannelName: map['agora_channel_name'] ?? '',
      agoraAppId: map['agora_app_id'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static DateTime _parseTimeFromString(String timeString) {
    // Parse time string like "14:30:00" into today's DateTime
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  String get timeString {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
  }
}

class VideoSessionInstance {
  final String id;
  final String videoSessionId;
  final DateTime scheduledDate;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final String? agoraToken;
  final int totalStudentsEnrolled;
  final int totalStudentsAttended;
  final DateTime createdAt;

  VideoSessionInstance({
    required this.id,
    required this.videoSessionId,
    required this.scheduledDate,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.status,
    this.agoraToken,
    required this.totalStudentsEnrolled,
    required this.totalStudentsAttended,
    required this.createdAt,
  });

  factory VideoSessionInstance.fromMap(Map<String, dynamic> map) {
    return VideoSessionInstance(
      id: map['id'] ?? '',
      videoSessionId: map['video_session_id'] ?? '',
      scheduledDate: DateTime.parse(map['scheduled_date']),
      scheduledStartTime: DateTime.parse(map['scheduled_start_time']),
      scheduledEndTime: DateTime.parse(map['scheduled_end_time']),
      actualStartTime: map['actual_start_time'] != null 
          ? DateTime.parse(map['actual_start_time']) 
          : null,
      actualEndTime: map['actual_end_time'] != null 
          ? DateTime.parse(map['actual_end_time']) 
          : null,
      status: map['status'] ?? 'scheduled',
      agoraToken: map['agora_token'],
      totalStudentsEnrolled: map['total_students_enrolled'] ?? 0,
      totalStudentsAttended: map['total_students_attended'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  bool get isScheduledToday {
    final today = DateTime.now();
    return scheduledDate.year == today.year &&
           scheduledDate.month == today.month &&
           scheduledDate.day == today.day;
  }

  Duration get timeUntilStart {
    return scheduledStartTime.difference(DateTime.now());
  }

  bool get hasStarted {
    return DateTime.now().isAfter(scheduledStartTime);
  }

  bool get hasEnded {
    return DateTime.now().isAfter(scheduledEndTime);
  }

  bool get isLive {
    return hasStarted && !hasEnded && status == 'ongoing';
  }
}

class SessionAttendance {
  final String id;
  final String sessionInstanceId;
  final String studentId;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int totalDurationMinutes;
  final bool isPresent;
  final DateTime createdAt;

  SessionAttendance({
    required this.id,
    required this.sessionInstanceId,
    required this.studentId,
    this.joinedAt,
    this.leftAt,
    required this.totalDurationMinutes,
    required this.isPresent,
    required this.createdAt,
  });

  factory SessionAttendance.fromMap(Map<String, dynamic> map) {
    return SessionAttendance(
      id: map['id'] ?? '',
      sessionInstanceId: map['session_instance_id'] ?? '',
      studentId: map['student_id'] ?? '',
      joinedAt: map['joined_at'] != null ? DateTime.parse(map['joined_at']) : null,
      leftAt: map['left_at'] != null ? DateTime.parse(map['left_at']) : null,
      totalDurationMinutes: map['total_duration_minutes'] ?? 0,
      isPresent: map['is_present'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class VideoSessionService extends ChangeNotifier {
  static final VideoSessionService _instance = VideoSessionService._internal();
  factory VideoSessionService() => _instance;
  VideoSessionService._internal();

  static VideoSessionService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  // RtcEngine? _agoraEngine; // Disabled for web compatibility

  List<VideoSession> _teacherVideoSessions = [];
  List<VideoSessionInstance> _studentUpcomingSessions = [];
  List<VideoSessionInstance> _teacherSessionInstances = [];
  bool _isLoading = false;

  List<VideoSession> get teacherVideoSessions => _teacherVideoSessions;
  List<VideoSessionInstance> get studentUpcomingSessions => _studentUpcomingSessions;
  List<VideoSessionInstance> get teacherSessionInstances => _teacherSessionInstances;
  bool get isLoading => _isLoading;

  // Initialize Agora Engine - Disabled for web compatibility
  Future<void> initializeAgora({required String appId}) async {
    debugPrint('Agora initialization disabled for web compatibility');
    // try {
    //   _agoraEngine = createAgoraRtcEngine();
    //   await _agoraEngine!.initialize(RtcEngineContext(appId: appId));
    //   await _agoraEngine!.enableVideo();
    //   debugPrint('Agora initialized successfully');
    // } catch (e) {
    //   debugPrint('Error initializing Agora: $e');
    //   rethrow;
    // }
  }

  // Create a new video session with recurring schedule
  Future<VideoSession?> createVideoSession({
    required String classId,
    required String title,
    String? description,
    required int durationMinutes,
    required DateTime startTime,
    required List<int> recurringDays,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate unique channel name
      final channelName = 'class_${classId}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _supabase.from('video_sessions').insert({
        'class_id': classId,
        'teacher_id': userId,
        'title': title,
        'description': description,
        'duration_minutes': durationMinutes,
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        'recurring_days': recurringDays,
        'agora_channel_name': channelName,
      }).select().single();

      final videoSession = VideoSession.fromMap(response);
      _teacherVideoSessions.add(videoSession);
      notifyListeners();

      debugPrint('Video session created: ${videoSession.id}');
      return videoSession;
    } catch (e) {
      debugPrint('Error creating video session: $e');
      return null;
    }
  }

  // Fetch teacher's video sessions
  Future<List<VideoSession>> fetchTeacherVideoSessions() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('video_sessions')
          .select('*')
          .eq('teacher_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _teacherVideoSessions = (response as List)
          .map((data) => VideoSession.fromMap(data))
          .toList();

      return _teacherVideoSessions;
    } catch (e) {
      debugPrint('Error fetching teacher video sessions: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch upcoming video session instances for students
  Future<List<VideoSessionInstance>> fetchStudentUpcomingSessions() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get sessions for classes the student is enrolled in
      final response = await _supabase
          .from('video_session_instances')
          .select('''
            *,
            video_sessions!inner(
              class_id,
              title,
              classes!inner(
                id,
                class_enrollments!inner(student_id)
              )
            )
          ''')
          .eq('video_sessions.classes.class_enrollments.student_id', userId)
          .eq('video_sessions.classes.class_enrollments.is_active', true)
          .gte('scheduled_start_time', DateTime.now().toIso8601String())
          .order('scheduled_start_time', ascending: true)
          .limit(20);

      _studentUpcomingSessions = (response as List)
          .map((data) => VideoSessionInstance.fromMap(data))
          .toList();

      return _studentUpcomingSessions;
    } catch (e) {
      debugPrint('Error fetching student upcoming sessions: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch session instances for teacher
  Future<List<VideoSessionInstance>> fetchTeacherSessionInstances(String videoSessionId) async {
    try {
      final response = await _supabase
          .from('video_session_instances')
          .select('*')
          .eq('video_session_id', videoSessionId)
          .order('scheduled_date', ascending: true);

      _teacherSessionInstances = (response as List)
          .map((data) => VideoSessionInstance.fromMap(data))
          .toList();

      return _teacherSessionInstances;
    } catch (e) {
      debugPrint('Error fetching session instances: $e');
      rethrow;
    }
  }

  // Start a video session instance
  Future<bool> startSessionInstance(String instanceId) async {
    try {
      await _supabase
          .from('video_session_instances')
          .update({
            'status': 'ongoing',
            'actual_start_time': DateTime.now().toIso8601String(),
          })
          .eq('id', instanceId);

      // Update local list
      final index = _teacherSessionInstances.indexWhere((instance) => instance.id == instanceId);
      if (index != -1) {
        // Refresh the specific instance
        await fetchTeacherSessionInstances(_teacherSessionInstances[index].videoSessionId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting session instance: $e');
      return false;
    }
  }

  // End a video session instance
  Future<bool> endSessionInstance(String instanceId) async {
    try {
      await _supabase
          .from('video_session_instances')
          .update({
            'status': 'completed',
            'actual_end_time': DateTime.now().toIso8601String(),
          })
          .eq('id', instanceId);

      // Calculate and update attendance counts
      await _updateAttendanceCounts(instanceId);

      // Update local list
      final index = _teacherSessionInstances.indexWhere((instance) => instance.id == instanceId);
      if (index != -1) {
        await fetchTeacherSessionInstances(_teacherSessionInstances[index].videoSessionId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error ending session instance: $e');
      return false;
    }
  }

  // Record student joining session
  Future<bool> recordStudentJoin(String instanceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('video_session_attendance').insert({
        'session_instance_id': instanceId,
        'student_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
        'is_present': true,
      });

      return true;
    } catch (e) {
      // If already exists, update join time
      try {
        await _supabase
            .from('video_session_attendance')
            .update({
              'joined_at': DateTime.now().toIso8601String(),
              'is_present': true,
            })
            .eq('session_instance_id', instanceId)
            .eq('student_id', _supabase.auth.currentUser!.id);
        return true;
      } catch (e2) {
        debugPrint('Error recording student join: $e2');
        return false;
      }
    }
  }

  // Record student leaving session
  Future<bool> recordStudentLeave(String instanceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get join time to calculate duration
      final attendanceResponse = await _supabase
          .from('video_session_attendance')
          .select('joined_at')
          .eq('session_instance_id', instanceId)
          .eq('student_id', userId)
          .single();

      final joinedAt = DateTime.parse(attendanceResponse['joined_at']);
      final duration = DateTime.now().difference(joinedAt).inMinutes;

      await _supabase
          .from('video_session_attendance')
          .update({
            'left_at': DateTime.now().toIso8601String(),
            'total_duration_minutes': duration,
          })
          .eq('session_instance_id', instanceId)
          .eq('student_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error recording student leave: $e');
      return false;
    }
  }

  // Get attendance report for a session instance
  Future<List<SessionAttendance>> getSessionAttendanceReport(String instanceId) async {
    try {
      final response = await _supabase
          .from('video_session_attendance')
          .select('*')
          .eq('session_instance_id', instanceId)
          .order('joined_at', ascending: true);

      return (response as List)
          .map((data) => SessionAttendance.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching attendance report: $e');
      rethrow;
    }
  }

  // Join Agora channel - Disabled for web compatibility
  Future<bool> joinAgoraChannel({
    required String channelName,
    required String token,
    required int uid,
  }) async {
    debugPrint('Agora channel join disabled for web compatibility');
    return false;
    // try {
    //   if (_agoraEngine == null) throw Exception('Agora not initialized');
    //   await _agoraEngine!.joinChannel(
    //     token: token,
    //     channelId: channelName,
    //     uid: uid,
    //     options: const ChannelMediaOptions(),
    //   );
    //   debugPrint('Joined Agora channel: $channelName');
    //   return true;
    // } catch (e) {
    //   debugPrint('Error joining Agora channel: $e');
    //   return false;
    // }
  }

  // Leave Agora channel - Disabled for web compatibility
  Future<bool> leaveAgoraChannel() async {
    debugPrint('Agora channel leave disabled for web compatibility');
    return false;
    // try {
    //   if (_agoraEngine == null) return false;
    //   await _agoraEngine!.leaveChannel();
    //   debugPrint('Left Agora channel');
    //   return true;
    // } catch (e) {
    //   debugPrint('Error leaving Agora channel: $e');
    //   return false;
    // }
  }

  // Dispose Agora engine - Disabled for web compatibility
  Future<void> disposeAgora() async {
    debugPrint('Agora dispose disabled for web compatibility');
    // try {
    //   await _agoraEngine?.leaveChannel();
    //   await _agoraEngine?.release();
    //   _agoraEngine = null;
    //   debugPrint('Agora disposed');
    // } catch (e) {
    //   debugPrint('Error disposing Agora: $e');
    // }
  }

  // Helper method to update attendance counts
  Future<void> _updateAttendanceCounts(String instanceId) async {
    try {
      final countResponse = await _supabase
          .from('video_session_attendance')
          .select('is_present')
          .eq('session_instance_id', instanceId);

      final attendedCount = (countResponse as List)
          .where((record) => record['is_present'] == true)
          .length;

      await _supabase
          .from('video_session_instances')
          .update({'total_students_attended': attendedCount})
          .eq('id', instanceId);
    } catch (e) {
      debugPrint('Error updating attendance counts: $e');
    }
  }

  // Delete video session
  Future<bool> deleteVideoSession(String sessionId) async {
    try {
      await _supabase
          .from('video_sessions')
          .update({'is_active': false})
          .eq('id', sessionId);

      _teacherVideoSessions.removeWhere((session) => session.id == sessionId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting video session: $e');
      return false;
    }
  }

  // RtcEngine? get agoraEngine => _agoraEngine; // Disabled for web compatibility
}