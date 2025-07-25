import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/video_session_service.dart';

class TeacherVideoSessionsScreen extends StatefulWidget {
  const TeacherVideoSessionsScreen({super.key});

  @override
  State<TeacherVideoSessionsScreen> createState() => _TeacherVideoSessionsScreenState();
}

class _TeacherVideoSessionsScreenState extends State<TeacherVideoSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideoSessions();
    });
  }

  Future<void> _loadVideoSessions() async {
    try {
      await context.read<VideoSessionService>().fetchTeacherVideoSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video sessions: $e'),
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
        title: const Text('My Video Sessions'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideoSessions,
          ),
        ],
      ),
      body: Consumer<VideoSessionService>(
        builder: (context, videoSessionService, child) {
          if (videoSessionService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = videoSessionService.teacherVideoSessions;

          if (sessions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadVideoSessions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(session);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createVideoSession,
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.video_call),
        label: const Text('Schedule Session'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_call_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Video Sessions Yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule your first video session to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createVideoSession,
            icon: const Icon(Icons.video_call),
            label: const Text('Schedule Session'),
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

  Widget _buildSessionCard(VideoSession session) {
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
              _buildSessionHeader(session),
              const SizedBox(height: 12),
              if (session.description != null) ...[
                _buildSessionDescription(session),
                const SizedBox(height: 12),
              ],
              _buildSessionInfo(session),
              const SizedBox(height: 16),
              _buildActionButtons(session),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHeader(VideoSession session) {
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
            Icons.video_call,
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
                session.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Channel: ${session.agoraChannelName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(session),
      ],
    );
  }

  Widget _buildStatusBadge(VideoSession session) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (session.isActive) {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
      text = 'ACTIVE';
    } else {
      backgroundColor = Colors.grey.withValues(alpha: 0.1);
      textColor = Colors.grey;
      text = 'INACTIVE';
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

  Widget _buildSessionDescription(VideoSession session) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Text(
        session.description!,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(VideoSession session) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.schedule,
          'Start Time',
          _formatTime(session.startTime),
        ),
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.timer,
          'Duration',
          '${session.durationMinutes} minutes',
        ),
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.calendar_today,
          'Recurring Days',
          _formatRecurringDays(session.recurringDays),
        ),
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.date_range,
          'Created',
          _formatCreatedDate(session.createdAt),
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

  Widget _buildActionButtons(VideoSession session) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewInstances(session),
            icon: const Icon(Icons.list, size: 16),
            label: const Text('View Sessions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7553F6),
              side: const BorderSide(color: Color(0xFF7553F6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _manageSession(session),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Manage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7553F6),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _createVideoSession() {
    // For now, let's show a message asking user to create from class detail
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Video Session'),
        content: const Text(
          'To schedule a video session, please go to your Classes tab, select a specific class, and use the "Schedule Video Session" button in the Quick Actions section.',
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

  void _viewInstances(VideoSession session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing session instances for "${session.title}"...'),
        backgroundColor: const Color(0xFF7553F6),
      ),
    );
  }

  void _manageSession(VideoSession session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Managing "${session.title}"...'),
        backgroundColor: const Color(0xFF7553F6),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatRecurringDays(List<int> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => dayNames[day - 1]).join(', ');
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