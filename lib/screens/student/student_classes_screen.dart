import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/class_service.dart';
import 'package:rive_animation/services/user_service.dart';
import 'package:rive_animation/screens/student/student_class_detail_screen.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassService>().fetchStudentEnrollments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<ClassService>(
                builder: (context, classService, child) {
                  if (classService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final enrollments = classService.studentEnrollments;

                  if (enrollments.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildEnrollmentsList(enrollments);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinClassDialog(context),
        backgroundColor: const Color(0xFF7553F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Join Class', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Classes',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<UserService>(
            builder: (context, userService, child) {
              return Text(
                'Welcome back, ${userService.currentUser?.fullName ?? 'Student'}!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Classes Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Join a class using your teacher\'s class code',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showJoinClassDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Join Your First Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7553F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList(List<ClassEnrollment> enrollments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        return _buildClassCard(enrollment);
      },
    );
  }

  Widget _buildClassCard(ClassEnrollment enrollment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewClassDetails(enrollment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7553F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_,
                      color: Color(0xFF7553F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.className ?? 'Unknown Class',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Teacher: ${enrollment.teacherName ?? 'Unknown'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleClassAction(value, enrollment),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(Icons.exit_to_app,
                                size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Leave Class',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Enrollment Info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Enrolled ${_formatEnrollmentDate(enrollment.enrolledAt)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEnrollmentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _viewClassDetails(ClassEnrollment enrollment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentClassDetailScreen(enrollment: enrollment),
      ),
    );
  }

  void _handleClassAction(String action, ClassEnrollment enrollment) {
    switch (action) {
      case 'leave':
        _showLeaveConfirmation(enrollment);
        break;
    }
  }

  void _showLeaveConfirmation(ClassEnrollment enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Class'),
        content: Text(
            'Are you sure you want to leave "${enrollment.className ?? 'this class'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context
                    .read<ClassService>()
                    .leaveClass(enrollment.classId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Left "${enrollment.className ?? 'class'}" successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error leaving class: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinClassDialog(),
    );
  }
}

class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({super.key});

  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Class'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 6-digit class code provided by your teacher',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Class Code',
                hintText: 'e.g. ABC123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a class code';
                }
                if (value.trim().length != 6) {
                  return 'Class code must be 6 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinClass,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7553F6),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Join Class'),
        ),
      ],
    );
  }

  Future<void> _joinClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final classService = context.read<ClassService>();
      final result =
          await classService.joinClassByCode(_codeController.text.trim());

      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${result['class_name']}"!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to join class');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}