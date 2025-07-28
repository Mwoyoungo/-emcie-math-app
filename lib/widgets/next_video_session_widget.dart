import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/video_session_service.dart';
import '../services/user_service.dart';
import '../model/video_session_model.dart';
import '../screens/teacher/video_session_detail_screen.dart';
import 'countdown_timer.dart';

class NextVideoSessionWidget extends StatefulWidget {
  const NextVideoSessionWidget({super.key});

  @override
  State<NextVideoSessionWidget> createState() => _NextVideoSessionWidgetState();
}

class _NextVideoSessionWidgetState extends State<NextVideoSessionWidget> {
  VideoSessionInstance? _nextSession;
  bool _isLoading = true;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    // Defer the async call to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNextSession();
    });
  }

  void _loadNextSession() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final videoSessionService = Provider.of<VideoSessionService>(context, listen: false);
      
      List<VideoSessionInstance> sessions = [];
      
      if (userService.isTeacher) {
        sessions = await videoSessionService.getUpcomingSessionInstances(refresh: true);
      } else {
        sessions = await videoSessionService.getStudentUpcomingSessions(refresh: true);
      }

      if (sessions.isNotEmpty) {
        // Get the next session (earliest scheduled start time)
        sessions.sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
        if (mounted) {
          setState(() {
            _nextSession = sessions.first;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading next session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_nextSession == null) {
      return _buildNoSessionWidget();
    }

    return _buildSessionWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: const Row(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF7553F6),
            strokeWidth: 2,
          ),
          SizedBox(width: 16),
          Text(
            'Loading next session...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.video_call_outlined,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your next video session will appear here',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionWidget() {
    final session = _nextSession?.videoSession;
    if (session == null) {
      return _buildNoSessionWidget();
    }
    
    final userService = Provider.of<UserService>(context, listen: false);
    final isTeacher = userService.isTeacher;

    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoSessionDetailScreen(
                  sessionInstance: _nextSession!,
                  isTeacher: isTeacher,
                ),
              ),
            ).then((_) => _loadNextSession());
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with session info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
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
                              fontSize: 18,
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
                          if (!isTeacher && session.teacherName != null) ...[
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
                      scheduledStartTime: _nextSession!.scheduledStartTime,
                      scheduledEndTime: _nextSession!.scheduledEndTime,
                      status: _nextSession!.status,
                      size: 16,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Session details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatTime(_nextSession!.scheduledStartTime)} - ${_formatTime(_nextSession!.scheduledEndTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(_nextSession!.scheduledDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Countdown or Action Section
                if (_nextSession!.isUpcoming) ...[
                  CountdownTimer(
                    targetTime: _nextSession!.scheduledStartTime,
                    label: isTeacher ? 'Session starts in' : 'Starts in',
                    primaryColor: const Color(0xFF7553F6),
                    showSeconds: false,
                    onComplete: () {
                      // Only refresh once when countdown completes
                      if (mounted) {
                        _loadNextSession();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ] else if (_nextSession!.isLive) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                        Expanded(
                          child: Text(
                            isTeacher ? 'Session is ready to start!' : 'Session is Live Now!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                _buildActionButtons(isTeacher),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTeacher) {
    if (isTeacher) {
      return _buildTeacherButtons();
    } else {
      return _buildStudentButtons();
    }
  }

  Widget _buildTeacherButtons() {
    if (_nextSession!.isLive) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Start Class',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openVideoLink,
              icon: const Icon(Icons.video_call, color: Color(0xFF7553F6)),
              label: const Text(
                'Join Video',
                style: TextStyle(
                  color: Color(0xFF7553F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF7553F6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoSessionDetailScreen(
                  sessionInstance: _nextSession!,
                  isTeacher: true,
                ),
              ),
            ).then((_) => _loadNextSession());
          },
          icon: const Icon(Icons.settings, color: Color(0xFF7553F6)),
          label: const Text(
            'Manage Session',
            style: TextStyle(
              color: Color(0xFF7553F6),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Color(0xFF7553F6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStudentButtons() {
    if (_nextSession!.isLive && !_hasJoined) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _joinSession,
          icon: const Icon(Icons.video_call, color: Colors.white),
          label: const Text(
            'Join Class',
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
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      );
    } else if (_hasJoined) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openVideoLink,
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: const Text(
                'Open Video',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
              onPressed: _leaveSession,
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text(
                'Leave',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
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
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _nextSession!.isUpcoming ? Icons.schedule : Icons.check_circle,
              color: Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _nextSession!.isUpcoming ? 'Session not started yet' : 'Session ended',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _startSession() async {
    final videoSessionService = Provider.of<VideoSessionService>(context, listen: false);
    final success = await videoSessionService.startSessionInstance(_nextSession!.id);
    
    if (!mounted) return;
    
    if (success) {
      setState(() {});
      _loadNextSession();
      
      // Also open the video link if available
      await _openVideoLink();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _joinSession() async {
    final videoSessionService = Provider.of<VideoSessionService>(context, listen: false);
    final success = await videoSessionService.joinSession(_nextSession!.id);
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _hasJoined = true;
      });
      
      // Open the video link
      await _openVideoLink();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined session successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _leaveSession() async {
    final videoSessionService = Provider.of<VideoSessionService>(context, listen: false);
    final success = await videoSessionService.leaveSession(_nextSession!.id);
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _hasJoined = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left session successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _openVideoLink() async {
    final session = _nextSession?.videoSession;
    if (session == null) {
      return; // Cannot open video link without session data
    }
    
    if (session.videoLink != null && session.videoLink!.isNotEmpty) {
      try {
        final uri = Uri.parse(session.videoLink!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch ${session.videoLink}';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open video link: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Show a dialog with session info if no video link
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Join Video Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No video link provided for this session.'),
              const SizedBox(height: 16),
              Text(
                'Session: ${session.title}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Channel: ${session.agoraChannelName}'),
            ],
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
  }

  Color _getStatusColor() {
    if (_nextSession!.isLive) return Colors.green;
    if (_nextSession!.isPast) return Colors.grey;
    return const Color(0xFF7553F6);
  }

  IconData _getStatusIcon() {
    if (_nextSession!.isLive) return Icons.play_circle;
    if (_nextSession!.isPast) return Icons.check_circle;
    return Icons.video_call;
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
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      return '$weekday, ${date.day}/${date.month}';
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