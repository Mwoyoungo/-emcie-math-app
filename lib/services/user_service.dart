import 'package:flutter/foundation.dart';

class UserData {
  final String fullName;
  final String grade;
  final String email;
  final String role;
  final String? subjectSpecialization;
  final String universityType;
  final String curriculum; // 'caps' or 'zimsec'

  UserData({
    required this.fullName,
    required this.grade,
    required this.email,
    this.role = 'student',
    this.subjectSpecialization,
    this.universityType = 'high_school',
    this.curriculum = 'caps',
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'grade': grade,
    'email': email,
    'role': role,
    'subjectSpecialization': subjectSpecialization,
    'universityType': universityType,
    'curriculum': curriculum,
  };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    fullName: json['fullName'] ?? '',
    grade: json['grade'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'student',
    subjectSpecialization: json['subjectSpecialization'],
    universityType: json['universityType'] ?? 'high_school',
    curriculum: json['curriculum'] ?? 'caps',
  );
}

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  UserData? _currentUser;

  UserData? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void setUser({
    required String fullName,
    required String grade,
    required String email,
    String role = 'student',
    String? subjectSpecialization,
    String universityType = 'high_school',
    String curriculum = 'caps',
  }) {
    _currentUser = UserData(
      fullName: fullName,
      grade: grade,
      email: email,
      role: role,
      subjectSpecialization: subjectSpecialization,
      universityType: universityType,
      curriculum: curriculum,
    );
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  String get firstName {
    if (_currentUser == null) return 'Student';
    final names = _currentUser!.fullName.split(' ');
    return names.isNotEmpty ? names.first : 'Student';
  }

  String get gradeDisplay {
    if (_currentUser == null) return 'Grade 12';
    if (_currentUser!.role == 'teacher') {
      return _currentUser!.subjectSpecialization ?? 'Teacher';
    }
    return 'Grade ${_currentUser!.grade}';
  }

  bool get isTeacher => _currentUser?.role == 'teacher';
  bool get isStudent => _currentUser?.role == 'student';
}