import 'package:flutter/material.dart';
import 'package:rive_animation/services/class_service.dart';

class SimplifiedStudentClassDetailScreen extends StatefulWidget {
  final ClassEnrollment enrollment;

  const SimplifiedStudentClassDetailScreen({
    super.key,
    required this.enrollment,
  });

  @override
  State<SimplifiedStudentClassDetailScreen> createState() => _SimplifiedStudentClassDetailScreenState();
}

class _SimplifiedStudentClassDetailScreenState extends State<SimplifiedStudentClassDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enrollment.className ?? 'Class'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassInfoCard(),
            const SizedBox(height: 20),
            _buildUpcomingSessionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7553F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.class_,
                    color: Color(0xFF7553F6),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.enrollment.className ?? 'Class',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.enrollment.teacherName != null)
                        Text(
                          'Teacher: ${widget.enrollment.teacherName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.schedule, 'Joined', _formatEnrollmentDate(widget.enrollment.enrolledAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNextSessionWidget(),
            const SizedBox(height: 16),
            _buildFutureSessionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7553F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7553F6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7553F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.video_call,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Session',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Math Review Session',
                      style: TextStyle(
                        color: Color(0xFF7553F6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  _getCountdownText(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7553F6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _joinSession,
              icon: const Icon(Icons.video_call, size: 16),
              label: const Text('Join Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7553F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureSessionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _buildSessionItem('Math Practice', 'Today, 3:00 PM', false),
        _buildSessionItem('Problem Solving', 'Tomorrow, 2:00 PM', false),
        _buildSessionItem('Review Session', 'Friday, 4:00 PM', false),
      ],
    );
  }

  Widget _buildSessionItem(String title, String time, bool isLive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLive 
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.video_call,
              color: isLive ? Colors.red : Colors.grey[600],
              size: 16,
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
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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

  void _joinSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Joining session...'),
        backgroundColor: Color(0xFF7553F6),
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
}