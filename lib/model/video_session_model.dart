class VideoSession {
  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String description;
  final int durationMinutes;
  final String startTime; // HH:MM format
  final List<int> recurringDays; // [1,2,3,4,5] for Mon-Fri
  final String agoraChannelName;
  final String? agoraAppId;
  final String? videoLink;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? className;
  final String? teacherName;

  VideoSession({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.startTime,
    required this.recurringDays,
    required this.agoraChannelName,
    this.agoraAppId,
    this.videoLink,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.className,
    this.teacherName,
  });

  factory VideoSession.fromJson(Map<String, dynamic> json) {
    return VideoSession(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      teacherId: json['teacher_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int,
      startTime: json['start_time'] as String,
      recurringDays: List<int>.from(json['recurring_days'] as List),
      agoraChannelName: json['agora_channel_name'] as String,
      agoraAppId: json['agora_app_id'] as String?,
      videoLink: json['video_link'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      className: json['class_name'] as String?,
      teacherName: json['teacher_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'start_time': startTime,
      'recurring_days': recurringDays,
      'agora_channel_name': agoraChannelName,
      'agora_app_id': agoraAppId,
      'video_link': videoLink,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VideoSession copyWith({
    String? id,
    String? classId,
    String? teacherId,
    String? title,
    String? description,
    int? durationMinutes,
    String? startTime,
    List<int>? recurringDays,
    String? agoraChannelName,
    String? agoraAppId,
    String? videoLink,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? className,
    String? teacherName,
  }) {
    return VideoSession(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      recurringDays: recurringDays ?? this.recurringDays,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
      agoraAppId: agoraAppId ?? this.agoraAppId,
      videoLink: videoLink ?? this.videoLink,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      className: className ?? this.className,
      teacherName: teacherName ?? this.teacherName,
    );
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
  final VideoSession? videoSession;

  VideoSessionInstance({
    required this.id,
    required this.videoSessionId,
    required this.scheduledDate,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    this.status = 'scheduled',
    this.agoraToken,
    this.totalStudentsEnrolled = 0,
    this.totalStudentsAttended = 0,
    required this.createdAt,
    this.videoSession,
  });

  factory VideoSessionInstance.fromJson(Map<String, dynamic> json) {
    return VideoSessionInstance(
      id: json['id'] as String,
      videoSessionId: json['video_session_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledStartTime: DateTime.parse(json['scheduled_start_time'] as String),
      scheduledEndTime: DateTime.parse(json['scheduled_end_time'] as String),
      actualStartTime: json['actual_start_time'] != null 
          ? DateTime.parse(json['actual_start_time'] as String) 
          : null,
      actualEndTime: json['actual_end_time'] != null 
          ? DateTime.parse(json['actual_end_time'] as String) 
          : null,
      status: json['status'] as String? ?? 'scheduled',
      agoraToken: json['agora_token'] as String?,
      totalStudentsEnrolled: json['total_students_enrolled'] as int? ?? 0,
      totalStudentsAttended: json['total_students_attended'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      videoSession: json['video_sessions'] != null 
          ? VideoSession.fromJson(json['video_sessions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_session_id': videoSessionId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'scheduled_end_time': scheduledEndTime.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'status': status,
      'agora_token': agoraToken,
      'total_students_enrolled': totalStudentsEnrolled,
      'total_students_attended': totalStudentsAttended,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return scheduledStartTime.isAfter(now) && status == 'scheduled';
  }

  bool get isLive {
    final now = DateTime.now();
    return status == 'ongoing' || 
           (now.isAfter(scheduledStartTime) && 
            now.isBefore(scheduledEndTime) && 
            status == 'scheduled');
  }

  bool get isPast {
    final now = DateTime.now();
    return scheduledEndTime.isBefore(now) || status == 'completed';
  }

  Duration get timeUntilStart {
    final now = DateTime.now();
    if (scheduledStartTime.isAfter(now)) {
      return scheduledStartTime.difference(now);
    }
    return Duration.zero;
  }

  Duration get timeUntilEnd {
    final now = DateTime.now();
    if (scheduledEndTime.isAfter(now)) {
      return scheduledEndTime.difference(now);
    }
    return Duration.zero;
  }

  bool get hasStarted {
    final now = DateTime.now();
    return now.isAfter(scheduledStartTime) || status == 'ongoing' || status == 'completed';
  }

  bool get hasEnded {
    final now = DateTime.now();
    return now.isAfter(scheduledEndTime) || status == 'completed' || status == 'cancelled';
  }
}

class VideoSessionAttendance {
  final String id;
  final String sessionInstanceId;
  final String studentId;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int totalDurationMinutes;
  final bool isPresent;
  final DateTime createdAt;
  final String? studentName;
  final String? studentEmail;

  VideoSessionAttendance({
    required this.id,
    required this.sessionInstanceId,
    required this.studentId,
    this.joinedAt,
    this.leftAt,
    this.totalDurationMinutes = 0,
    this.isPresent = false,
    required this.createdAt,
    this.studentName,
    this.studentEmail,
  });

  factory VideoSessionAttendance.fromJson(Map<String, dynamic> json) {
    return VideoSessionAttendance(
      id: json['id'] as String,
      sessionInstanceId: json['session_instance_id'] as String,
      studentId: json['student_id'] as String,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String) 
          : null,
      leftAt: json['left_at'] != null 
          ? DateTime.parse(json['left_at'] as String) 
          : null,
      totalDurationMinutes: json['total_duration_minutes'] as int? ?? 0,
      isPresent: json['is_present'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      studentName: json['student_name'] as String?,
      studentEmail: json['student_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_instance_id': sessionInstanceId,
      'student_id': studentId,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'total_duration_minutes': totalDurationMinutes,
      'is_present': isPresent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CreateVideoSessionRequest {
  final String classId;
  final String title;
  final String description;
  final int durationMinutes;
  final String startTime;
  final List<int> recurringDays;
  final String? videoLink; // For simple video link functionality

  CreateVideoSessionRequest({
    required this.classId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.startTime,
    required this.recurringDays,
    this.videoLink,
  });

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'start_time': startTime,
      'recurring_days': recurringDays,
      'video_link': videoLink,
    };
  }
}

class UpdateVideoSessionRequest {
  final String? title;
  final String? description;
  final int? durationMinutes;
  final String? startTime;
  final List<int>? recurringDays;
  final bool? isActive;
  final String? videoLink;

  UpdateVideoSessionRequest({
    this.title,
    this.description,
    this.durationMinutes,
    this.startTime,
    this.recurringDays,
    this.isActive,
    this.videoLink,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (durationMinutes != null) data['duration_minutes'] = durationMinutes;
    if (startTime != null) data['start_time'] = startTime;
    if (recurringDays != null) data['recurring_days'] = recurringDays;
    if (isActive != null) data['is_active'] = isActive;
    if (videoLink != null) data['video_link'] = videoLink;
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }
}

// Helper class for day selection
class WeekDay {
  final int value;
  final String name;
  final String shortName;

  const WeekDay({
    required this.value,
    required this.name,
    required this.shortName,
  });

  static const List<WeekDay> weekDays = [
    WeekDay(value: 1, name: 'Monday', shortName: 'Mon'),
    WeekDay(value: 2, name: 'Tuesday', shortName: 'Tue'),
    WeekDay(value: 3, name: 'Wednesday', shortName: 'Wed'),
    WeekDay(value: 4, name: 'Thursday', shortName: 'Thu'),
    WeekDay(value: 5, name: 'Friday', shortName: 'Fri'),
    WeekDay(value: 6, name: 'Saturday', shortName: 'Sat'),
    WeekDay(value: 7, name: 'Sunday', shortName: 'Sun'),
  ];

  static String getDaysString(List<int> days) {
    if (days.isEmpty) return 'No days selected';
    
    final selectedDays = weekDays.where((day) => days.contains(day.value)).toList();
    if (selectedDays.length == 7) return 'Daily';
    if (selectedDays.length == 5 && 
        selectedDays.every((day) => day.value >= 1 && day.value <= 5)) {
      return 'Weekdays';
    }
    if (selectedDays.length == 2 && 
        selectedDays.any((day) => day.value == 6) && 
        selectedDays.any((day) => day.value == 7)) {
      return 'Weekends';
    }
    
    return selectedDays.map((day) => day.shortName).join(', ');
  }
}