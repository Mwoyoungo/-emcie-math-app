import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/class_model.dart';
import '../../model/video_session_model.dart';
import '../../services/video_session_service.dart';
import '../../widgets/countdown_timer.dart';

class ClassVideoSessionsScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassVideoSessionsScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassVideoSessionsScreen> createState() =>
      _ClassVideoSessionsScreenState();
}

class _ClassVideoSessionsScreenState extends State<ClassVideoSessionsScreen> {
  List<VideoSessionInstance> _classSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassSessions();
  }

  Future<void> _loadClassSessions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final videoSessionService =
          Provider.of<VideoSessionService>(context, listen: false);
      final allSessions =
          await videoSessionService.getStudentUpcomingSessions(refresh: true);

      // Filter sessions for this specific class
      final classSessions = allSessions
          .where((session) =>
              session.videoSession?.classId == widget.classModel.id)
          .toList();

      // Sort by scheduled time
      classSessions
          .sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));

      if (mounted) {
        setState(() {
          _classSessions = classSessions;
        });
      }
    } catch (e) {
      debugPrint('Error loading class sessions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinSession(VideoSessionInstance session) async {
    final videoLink = session.videoSession?.videoLink;

    if (videoLink != null && videoLink.isNotEmpty) {
      try {
        final uri = Uri.parse(videoLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Record attendance
          if (mounted) {
            final videoSessionService =
                Provider.of<VideoSessionService>(context, listen: false);
            await videoSessionService.joinSession(session.id);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot open video link')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening link: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No video link available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classModel.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Video Sessions',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classSessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No video sessions scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teacher hasn\'t scheduled any sessions yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classSessions.length,
      itemBuilder: (context, index) {
        final session = _classSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(VideoSessionInstance session) {
    final videoSession = session.videoSession!;
    final isLive = session.isLive;
    final isUpcoming = session.isUpcoming;
    final hasVideoLink =
        videoSession.videoLink != null && videoSession.videoLink!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.green.withValues(alpha: 0.1)
                        : isUpcoming
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLive
                            ? Icons.fiber_manual_record
                            : isUpcoming
                                ? Icons.schedule
                                : Icons.check_circle,
                        size: 12,
                        color: isLive
                            ? Colors.green
                            : isUpcoming
                                ? Colors.blue
                                : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive
                            ? 'LIVE'
                            : isUpcoming
                                ? 'Upcoming'
                                : 'Ended',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLive
                              ? Colors.green
                              : isUpcoming
                                  ? Colors.blue
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasVideoLink && (isLive || isUpcoming))
                  Icon(
                    Icons.videocam,
                    color: Colors.green[600],
                    size: 20,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Session Title
            Text(
              videoSession.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            if (videoSession.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                videoSession.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Session Time
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(session.scheduledStartTime)} - ${_formatTime(session.scheduledEndTime)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(session.scheduledDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Countdown Timer for Upcoming Sessions
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              CountdownTimer(
                targetTime: session.scheduledStartTime,
                label: 'Starts in',
                primaryColor: const Color(0xFF7553F6),
                showSeconds: false,
                onComplete: () {
                  if (mounted) {
                    _loadClassSessions();
                  }
                },
              ),
            ],

            // Join Button
            if (hasVideoLink && (isLive || isUpcoming)) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _joinSession(session),
                  icon: Icon(
                    isLive ? Icons.play_circle : Icons.videocam,
                    color: Colors.white,
                  ),
                  label: Text(
                    isLive ? 'Join Live Session' : 'Join When Ready',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isLive ? Colors.green : const Color(0xFF7553F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
}
