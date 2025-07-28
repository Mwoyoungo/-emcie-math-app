import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/video_session_service.dart';
import 'package:rive_animation/model/video_session_model.dart';
import 'dart:async';

class StudentVideoSessionsScreen extends StatefulWidget {
  const StudentVideoSessionsScreen({super.key});

  @override
  State<StudentVideoSessionsScreen> createState() =>
      _StudentVideoSessionsScreenState();
}

class _StudentVideoSessionsScreenState
    extends State<StudentVideoSessionsScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUpcomingSessions();
      _startCountdownTimer();
    });
  }

  @override
  void dispose() {
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

  Future<void> _loadUpcomingSessions() async {
    if (!mounted) return;
    
    try {
      await context.read<VideoSessionService>().getStudentUpcomingSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sessions: $e'),
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
        title: const Text('Video Sessions'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUpcomingSessions,
          ),
        ],
      ),
      body: Consumer<VideoSessionService>(
        builder: (context, videoSessionService, child) {
          if (videoSessionService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final upcomingSessions = videoSessionService.studentSessions;

          if (upcomingSessions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadUpcomingSessions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: upcomingSessions.length,
              itemBuilder: (context, index) {
                final session = upcomingSessions[index];
                return _buildSessionCard(session);
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
            Icons.video_call_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Upcoming Sessions',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teachers haven\'t scheduled any video sessions yet',
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

  Widget _buildSessionCard(VideoSessionInstance session) {
    final timeUntilStart = session.timeUntilStart;
    final isLive = session.isLive;
    final hasStarted = session.hasStarted;
    final hasEnded = session.hasEnded;

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
              _buildSessionInfo(session),
              const SizedBox(height: 16),
              _buildCountdownSection(
                  session, timeUntilStart, isLive, hasStarted, hasEnded),
              const SizedBox(height: 16),
              _buildActionButton(session, isLive, hasStarted, hasEnded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHeader(VideoSessionInstance session) {
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
              const Text(
                'Math Session', // We'd need to get this from the video session
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Class Session',
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

  Widget _buildStatusBadge(VideoSessionInstance session) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (session.isLive) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
      text = 'LIVE';
    } else if (session.hasStarted && !session.hasEnded) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
      text = 'ONGOING';
    } else if (session.hasEnded) {
      backgroundColor = Colors.grey;
      textColor = Colors.white;
      text = 'ENDED';
    } else {
      backgroundColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue;
      text = 'UPCOMING';
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

  Widget _buildSessionInfo(VideoSessionInstance session) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.schedule,
          'Start Time',
          _formatDateTime(session.scheduledStartTime),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.timer,
          'Duration',
          _formatDuration(
              session.scheduledEndTime.difference(session.scheduledStartTime)),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.calendar_today,
          'Date',
          _formatDate(session.scheduledDate),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection(
    VideoSessionInstance session,
    Duration timeUntilStart,
    bool isLive,
    bool hasStarted,
    bool hasEnded,
  ) {
    if (hasEnded) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.grey, size: 20),
            SizedBox(width: 8),
            Text(
              'Session has ended',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (isLive) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Session is LIVE now!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (hasStarted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'Session has started',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Upcoming session countdown
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7553F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Starts in:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7553F6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCountdown(timeUntilStart),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7553F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    VideoSessionInstance session,
    bool isLive,
    bool hasStarted,
    bool hasEnded,
  ) {
    if (hasEnded) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Session Ended',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (isLive || hasStarted) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _joinSession(session),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLive ? Colors.red : Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_call, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                isLive ? 'Join Now' : 'Join Session',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Upcoming session
    final timeUntilStart = session.timeUntilStart;
    final canJoinSoon =
        timeUntilStart.inMinutes <= 5; // Allow joining 5 minutes before

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: canJoinSoon ? () => _joinSession(session) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canJoinSoon ? const Color(0xFF7553F6) : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          canJoinSoon ? 'Ready to Join' : 'Not Yet Available',
          style: TextStyle(
            color: canJoinSoon ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _joinSession(VideoSessionInstance session) async {
    if (!mounted) return;
    
    // TODO: Navigate to video call screen with Agora
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Joining video session...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Record attendance
    try {
      await context.read<VideoSessionService>().recordStudentJoin(session.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weekday = weekdays[date.weekday - 1];
      return '$weekday, ${date.day}/${date.month}';
    }
  }

  String _formatCountdown(Duration duration) {
    if (duration.isNegative) return '00:00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
