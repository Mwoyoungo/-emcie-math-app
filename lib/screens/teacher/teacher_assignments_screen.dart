import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/assignment_service.dart';
import 'package:rive_animation/screens/teacher/create_assignment_screen.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments() async {
    try {
      await context.read<AssignmentService>().fetchTeacherAssignments();
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
        title: const Text('My Assignments'),
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

          final assignments = assignmentService.teacherAssignments;

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
                return _buildAssignmentCard(assignment);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAssignment,
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Assignment'),
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
            'Create your first assignment to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createAssignment,
            icon: const Icon(Icons.add),
            label: const Text('Create Assignment'),
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

  Widget _buildAssignmentCard(Assignment assignment) {
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
              _buildAssignmentHeader(assignment),
              const SizedBox(height: 12),
              if (assignment.description != null) ...[
                _buildAssignmentDescription(assignment),
                const SizedBox(height: 12),
              ],
              _buildAssignmentInfo(assignment),
              const SizedBox(height: 16),
              _buildActionButtons(assignment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentHeader(Assignment assignment) {
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
                'Due: ${_formatDueDate(assignment.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: assignment.isOverdue ? Colors.red : Colors.grey[600],
                  fontWeight: assignment.isOverdue ? FontWeight.w500 : null,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(assignment),
      ],
    );
  }

  Widget _buildStatusBadge(Assignment assignment) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (assignment.isOverdue) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
      text = 'OVERDUE';
    } else {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
      text = 'ACTIVE';
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
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.people,
          'Created',
          _formatCreatedDate(assignment.createdAt),
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

  Widget _buildActionButtons(Assignment assignment) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewSubmissions(assignment),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View Submissions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7553F6),
              side: const BorderSide(color: Color(0xFF7553F6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _editAssignment(assignment),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7553F6),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _createAssignment() {
    // For now, let's show a message asking user to create from class detail
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Assignment'),
        content: const Text(
          'To create an assignment, please go to your Classes tab, select a specific class, and use the "Create Assignment" button in the Quick Actions section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewSubmissions(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing submissions for "${assignment.title}"...'),
        backgroundColor: const Color(0xFF7553F6),
      ),
    );
  }

  void _editAssignment(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing "${assignment.title}"...'),
        backgroundColor: const Color(0xFF7553F6),
      ),
    );
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

  String _formatCreatedDate(DateTime date) {
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
}