import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rive_animation/services/assignment_service.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments() async {
    try {
      final assignmentService = context.read<AssignmentService>();
      await assignmentService.fetchStudentAssignments();
      await assignmentService.fetchStudentSubmissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assignments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignments,
          ),
        ],
      ),
      body: Consumer<AssignmentService>(
        builder: (context, assignmentService, child) {
          if (assignmentService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = assignmentService.studentAssignments;

          if (assignments.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadAssignments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return _buildAssignmentCard(assignment, assignmentService);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Assignments Yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teachers haven\'t assigned any work yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment, AssignmentService assignmentService) {
    final submission = assignmentService.studentSubmissions
        .where((s) => s.assignmentId == assignment.id)
        .firstOrNull;

    final hasSubmitted = submission != null;
    final isOverdue = assignment.isOverdue && !hasSubmitted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssignmentHeader(assignment, hasSubmitted, isOverdue),
              const SizedBox(height: 12),
              _buildAssignmentDescription(assignment),
              const SizedBox(height: 12),
              _buildAssignmentInfo(assignment),
              const SizedBox(height: 16),
              _buildSubmissionSection(assignment, submission, hasSubmitted, isOverdue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentHeader(Assignment assignment, bool hasSubmitted, bool isOverdue) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF7553F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.assignment,
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
                assignment.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Due: ${assignment.dueDateFormatted}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontWeight: isOverdue ? FontWeight.w500 : null,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(hasSubmitted, isOverdue),
      ],
    );
  }

  Widget _buildStatusBadge(bool hasSubmitted, bool isOverdue) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (hasSubmitted) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      text = 'SUBMITTED';
    } else if (isOverdue) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
      text = 'OVERDUE';
    } else {
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange;
      text = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAssignmentDescription(Assignment assignment) {
    if (assignment.description == null || assignment.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Text(
        assignment.description!,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildAssignmentInfo(Assignment assignment) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.schedule,
          'Due Date',
          _formatDueDate(assignment.dueDate),
          assignment.isOverdue ? Colors.red : null,
        ),
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.file_upload,
          'Max File Size',
          '${assignment.maxFileSizeMb}MB',
        ),
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.description,
          'Allowed Types',
          assignment.allowedFileTypes.map((e) => e.toUpperCase()).join(', '),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? textColor]) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionSection(Assignment assignment, AssignmentSubmission? submission, bool hasSubmitted, bool isOverdue) {
    if (hasSubmitted && submission != null) {
      return _buildSubmissionInfo(submission);
    }

    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Assignment is overdue',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () => _submitAssignment(assignment),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7553F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Submit Assignment',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionInfo(AssignmentSubmission submission) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Submitted',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _formatSubmissionDate(submission.submittedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.attachment, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  submission.fileName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                submission.fileSizeDisplay,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (submission.isGraded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grade, color: Colors.blue, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Grade: ${submission.gradeDisplay}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitAssignment(Assignment assignment) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: assignment.allowedFileTypes,
        allowMultiple: false,
      );

      if (result != null && result.files.single.size <= assignment.maxFileSizeMb * 1024 * 1024) {
        PlatformFile file = result.files.first;

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading assignment...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Submit assignment
        final success = await context.read<AssignmentService>().submitAssignment(
          assignmentId: assignment.id,
          file: file,
        );

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Assignment submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit assignment. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (result != null) {
        // File too large
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File size exceeds ${assignment.maxFileSizeMb}MB limit'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    String dayText;
    if (dueDay == today) {
      dayText = 'Today';
    } else if (dueDay == tomorrow) {
      dayText = 'Tomorrow';
    } else {
      dayText = '${date.day}/${date.month}/${date.year}';
    }

    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dayText at $time';
  }

  String _formatSubmissionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}