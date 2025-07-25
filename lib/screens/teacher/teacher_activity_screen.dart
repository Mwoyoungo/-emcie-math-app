import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/assignment_service.dart';
import 'package:rive_animation/services/video_session_service.dart';
import 'dart:async';

class TeacherActivityScreen extends StatefulWidget {
  const TeacherActivityScreen({super.key});

  @override
  State<TeacherActivityScreen> createState() => _TeacherActivityScreenState();
}

class _TeacherActivityScreenState extends State<TeacherActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _startCountdownTimer();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Rebuild to update countdown timers
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      await context.read<AssignmentService>().fetchTeacherAssignments();
      await context.read<VideoSessionService>().fetchTeacherVideoSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
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
        title: const Text('My Activity'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Assignments'),
            Tab(text: 'Sessions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentsTab(),
          _buildSessionsTab(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Consumer<AssignmentService>(
      builder: (context, assignmentService, child) {
        if (assignmentService.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading assignments...'),
              ],
            ),
          );
        }

        final assignments = assignmentService.teacherAssignments;

        if (assignments.isEmpty) {
          return _buildEmptyAssignments();
        }

        return RefreshIndicator(
          onRefresh: () => assignmentService.fetchTeacherAssignments(),
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
    );
  }

  Widget _buildSessionsTab() {
    return Consumer<VideoSessionService>(
      builder: (context, videoSessionService, child) {
        if (videoSessionService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // For now, show upcoming sessions widget
        return RefreshIndicator(
          onRefresh: () => videoSessionService.fetchTeacherVideoSessions(),
          child: _buildUpcomingSessionsWidget(),
        );
      },
    );
  }

  Widget _buildEmptyAssignments() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF7553F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64,
                color: const Color(0xFF7553F6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Assignments Created',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a1a),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create assignments for your students from your class pages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to Classes tab
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to your Classes to create assignments'),
                    backgroundColor: Color(0xFF7553F6),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Assignment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7553F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7553F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.assignment,
            color: Color(0xFF7553F6),
            size: 20,
          ),
        ),
        title: Text(
          assignment.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Due: ${_formatDueDate(assignment.dueDate)}'),
        trailing: _buildAssignmentStatus(assignment),
        onTap: () => _viewAssignmentDetails(assignment),
      ),
    );
  }

  Widget _buildAssignmentStatus(Assignment assignment) {
    if (assignment.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'OVERDUE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const Icon(Icons.chevron_right);
  }

  Widget _buildUpcomingSessionsWidget() {
    return Consumer<VideoSessionService>(
      builder: (context, videoSessionService, child) {
        // This would normally fetch next upcoming session
        // For now, showing a placeholder
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNextSessionCard(),
            const SizedBox(height: 16),
            _buildRecentSessionsCard(),
          ],
        );
      },
    );
  }

  Widget _buildNextSessionCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7553F6).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7553F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_call,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Upcoming Session',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Next Scheduled Session',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7553F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Starts in:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7553F6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCountdownText(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7553F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _startClass,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7553F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSessionItem('Math Review', 'Completed', '2 hours ago', Colors.green),
            _buildSessionItem('Algebra Basics', 'Completed', '1 day ago', Colors.green),
            _buildSessionItem('Problem Solving', 'Missed', '2 days ago', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(String title, String status, String time, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$status • $time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCountdownText() {
    // Placeholder countdown - in real app this would be calculated from next session
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final difference = nextHour.difference(now);
    
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _viewAssignmentDetails(Assignment assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing "${assignment.title}"'),
        backgroundColor: const Color(0xFF7553F6),
      ),
    );
  }

  void _startClass() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Video Session'),
        content: const Text(
          'This will create a video meeting link and notify your students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video session started! Students will be notified.'),
                  backgroundColor: Color(0xFF7553F6),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7553F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return '${difference.inMinutes} minutes left';
    }
  }
}