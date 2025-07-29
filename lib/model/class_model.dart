class ClassModel {
  final String id;
  final String teacherId;
  final String name;
  final String description;
  final String subject;
  final String gradeLevel;
  final String classCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? enrolledStudentsCount;
  final String? teacherName;
  final String? whatsappCallLink;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.description,
    required this.subject,
    required this.gradeLevel,
    required this.classCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.enrolledStudentsCount,
    this.teacherName,
    this.whatsappCallLink,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      subject: json['subject'] as String? ?? 'Mathematics',
      gradeLevel: json['grade_level'] as String,
      classCode: json['class_code'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      enrolledStudentsCount: json['enrolled_students_count'] as int?,
      teacherName: json['teacher_name'] as String?,
      whatsappCallLink: json['whatsapp_call_link'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'name': name,
      'description': description,
      'subject': subject,
      'grade_level': gradeLevel,
      'class_code': classCode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'whatsapp_call_link': whatsappCallLink,
    };
  }

  ClassModel copyWith({
    String? id,
    String? teacherId,
    String? name,
    String? description,
    String? subject,
    String? gradeLevel,
    String? classCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? enrolledStudentsCount,
    String? teacherName,
    String? whatsappCallLink,
  }) {
    return ClassModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      classCode: classCode ?? this.classCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enrolledStudentsCount: enrolledStudentsCount ?? this.enrolledStudentsCount,
      teacherName: teacherName ?? this.teacherName,
      whatsappCallLink: whatsappCallLink ?? this.whatsappCallLink,
    );
  }
}

class ClassEnrollment {
  final String id;
  final String classId;
  final String studentId;
  final DateTime enrolledAt;
  final bool isActive;
  final String? studentName;
  final String? studentEmail;
  final String? studentGrade;

  ClassEnrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.enrolledAt,
    this.isActive = true,
    this.studentName,
    this.studentEmail,
    this.studentGrade,
  });

  factory ClassEnrollment.fromJson(Map<String, dynamic> json) {
    return ClassEnrollment(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      studentName: json['student_name'] as String?,
      studentEmail: json['student_email'] as String?,
      studentGrade: json['student_grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'student_id': studentId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class CreateClassRequest {
  final String name;
  final String description;
  final String subject;
  final String gradeLevel;
  final String? whatsappCallLink;

  CreateClassRequest({
    required this.name,
    required this.description,
    required this.subject,
    required this.gradeLevel,
    this.whatsappCallLink,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'subject': subject,
      'grade_level': gradeLevel,
      'whatsapp_call_link': whatsappCallLink,
    };
  }
}

class UpdateClassRequest {
  final String? name;
  final String? description;
  final String? subject;
  final String? gradeLevel;
  final bool? isActive;
  final String? whatsappCallLink;

  UpdateClassRequest({
    this.name,
    this.description,
    this.subject,
    this.gradeLevel,
    this.isActive,
    this.whatsappCallLink,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (subject != null) data['subject'] = subject;
    if (gradeLevel != null) data['grade_level'] = gradeLevel;
    if (isActive != null) data['is_active'] = isActive;
    if (whatsappCallLink != null) data['whatsapp_call_link'] = whatsappCallLink;
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }
}

class JoinClassResult {
  final bool success;
  final String? error;
  final String? enrollmentId;
  final String? classId;

  JoinClassResult({
    required this.success,
    this.error,
    this.enrollmentId,
    this.classId,
  });

  factory JoinClassResult.fromJson(Map<String, dynamic> json) {
    return JoinClassResult(
      success: json['success'] as bool,
      error: json['error'] as String?,
      enrollmentId: json['enrollment_id'] as String?,
      classId: json['class_id'] as String?,
    );
  }
}