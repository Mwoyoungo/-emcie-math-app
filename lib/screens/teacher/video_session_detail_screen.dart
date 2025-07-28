import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/video_session_service.dart';
import '../../model/video_session_model.dart';
import '../../widgets/countdown_timer.dart';

class VideoSessionDetailScreen extends StatefulWidget {
  final VideoSessionInstance sessionInstance;
  final bool isTeacher;

  const VideoSessionDetailScreen({
    super.key,
    required this.sessionInstance,
    this.isTeacher = false,
  });

  @override
  State<VideoSessionDetailScreen> createState() =>
      _VideoSessionDetailScreenState();
}

class _VideoSessionDetailScreenState extends State<VideoSessionDetailScreen> {
  List<VideoSessionAttendance> _attendance = [];
  bool _isLoadingAttendance = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    if (widget.isTeacher) {
      _loadAttendance();
    }
  }

  void _loadAttendance() async {
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final videoSessionService =
          Provider.of<VideoSessionService>(context, listen: false);
      final attendance = await videoSessionService
          .getSessionAttendance(widget.sessionInstance.id);

      if (mounted) {
        setState(() {
          _attendance = attendance;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionInstance.videoSession;
    if (session == null) {
      return const Scaffold(
        body: Center(
          child: Text('Session not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Video Session',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Session Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7553F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.video_call,
                          color: Color(0xFF7553F6),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.className ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (session.teacherName != null &&
                                !widget.isTeacher) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Teacher: ${session.teacherName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SessionStatusIndicator(
                        scheduledStartTime:
                            widget.sessionInstance.scheduledStartTime,
                        scheduledEndTime:
                            widget.sessionInstance.scheduledEndTime,
                        status: widget.sessionInstance.status,
                        size: 18,
                      ),
                    ],
                  ),

                  if (session.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      session.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Session Details
                  Row(
                    children: [
                      _buildDetailItem(
                        Icons.calendar_today,
                        'Date',
                        _formatDate(widget.sessionInstance.scheduledDate),
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        Icons.access_time,
                        'Time',
                        '${_formatTime(widget.sessionInstance.scheduledStartTime)} - ${_formatTime(widget.sessionInstance.scheduledEndTime)}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildDetailItem(
                        Icons.timer,
                        'Duration',
                        '${session.durationMinutes} minutes',
                      ),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        Icons.repeat,
                        'Recurring',
                        WeekDay.getDaysString(session.recurringDays),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Countdown/Action Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (widget.sessionInstance.isUpcoming) ...[
                    CountdownTimer(
                      targetTime: widget.sessionInstance.scheduledStartTime,
                      label:
                          widget.isTeacher ? 'Session starts in' : 'Starts in',
                      primaryColor: const Color(0xFF7553F6),
                      onComplete: () {
                        setState(() {}); // Refresh UI when countdown completes
                      },
                    ),
                  ] else if (widget.sessionInstance.isLive) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Session is Live Now!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (widget.sessionInstance.isPast) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.grey,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Session Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  if (widget.isTeacher) ...[
                    _buildTeacherActions(),
                  ] else ...[
                    _buildStudentActions(),
                  ],
                ],
              ),
            ),

            // Attendance Section (Teachers only)
            if (widget.isTeacher) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (_attendance.isNotEmpty)
                          Text(
                            '${_attendance.where((a) => a.isPresent).length}/${_attendance.length} present',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAttendanceList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherActions() {
    return Column(
      children: [
        if (widget.sessionInstance.isLive) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startSession,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Start Session',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _endSession,
                  icon: const Icon(Icons.stop, color: Colors.red),
                  label: const Text(
                    'End Session',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.sessionInstance.isUpcoming ? null : null,
              icon: const Icon(Icons.settings),
              label: const Text('Session Settings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentActions() {
    return Column(
      children: [
        if (widget.sessionInstance.isLive && !_hasJoined) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _joinSession,
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: const Text(
                'Join Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ] else if (_hasJoined) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _leaveSession,
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text(
                'Leave Session',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ] else if (widget.sessionInstance.isUpcoming) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Session not started yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Session has ended',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoadingAttendance) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7553F6)),
      );
    }

    if (_attendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No attendance recorded yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _attendance.map((attendance) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: attendance.isPresent
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                child: Icon(
                  attendance.isPresent ? Icons.check : Icons.close,
                  size: 16,
                  color: attendance.isPresent ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.studentName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (attendance.joinedAt != null)
                      Text(
                        'Joined at ${_formatTime(attendance.joinedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (attendance.totalDurationMinutes > 0)
                Text(
                  '${attendance.totalDurationMinutes}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _startSession() async {
    final videoSessionService =
        Provider.of<VideoSessionService>(context, listen: false);
    final success = await videoSessionService
        .startSessionInstance(widget.sessionInstance.id);

    if (!mounted) return;

    if (success) {
      setState(() {}); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session started successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start session'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _endSession() async {
    final videoSessionService =
        Provider.of<VideoSessionService>(context, listen: false);
    final success =
        await videoSessionService.endSessionInstance(widget.sessionInstance.id);

    if (!mounted) return;

    if (success) {
      setState(() {}); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session ended successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to end session'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _joinSession() async {
    final videoSessionService =
        Provider.of<VideoSessionService>(context, listen: false);
    final success =
        await videoSessionService.joinSession(widget.sessionInstance.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasJoined = true;
      });

      // If there's a video link, try to open it
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined session successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Here you would typically open the video call link
      // _openVideoLink();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join session'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _leaveSession() async {
    final videoSessionService =
        Provider.of<VideoSessionService>(context, listen: false);
    final success =
        await videoSessionService.leaveSession(widget.sessionInstance.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasJoined = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left session successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to leave session'),
          backgroundColor: Colors.red,
        ),
      );
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
      final weekday = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][date.weekday - 1];
      return '$weekday, ${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
