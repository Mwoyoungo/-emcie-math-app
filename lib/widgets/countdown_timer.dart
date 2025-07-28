import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final String label;
  final VoidCallback? onComplete;
  final Color? primaryColor;
  final Color? backgroundColor;
  final bool showSeconds;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;

  const CountdownTimer({
    super.key,
    required this.targetTime,
    required this.label,
    this.onComplete,
    this.primaryColor,
    this.backgroundColor,
    this.showSeconds = true,
    this.textStyle,
    this.labelStyle,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      setState(() {
        _remainingTime = widget.targetTime.difference(now);
        _isComplete = false;
      });
    } else {
      setState(() {
        _remainingTime = Duration.zero;
        _isComplete = true;
      });
      
      if (!_isComplete) {
        widget.onComplete?.call();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
      
      if (_isComplete) {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return widget.showSeconds ? "00:00:00" : "00:00";
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (widget.showSeconds) {
      return "${hours.toString().padLeft(2, '0')}:"
             "${minutes.toString().padLeft(2, '0')}:"
             "${seconds.toString().padLeft(2, '0')}";
    } else {
      return "${hours.toString().padLeft(2, '0')}:"
             "${minutes.toString().padLeft(2, '0')}";
    }
  }

  String _getTimeLabel() {
    if (_isComplete) return "Time's up!";
    
    final totalHours = _remainingTime.inHours;
    final totalMinutes = _remainingTime.inMinutes;
    final totalSeconds = _remainingTime.inSeconds;

    if (totalHours > 24) {
      final days = totalHours ~/ 24;
      return "in $days day${days > 1 ? 's' : ''}";
    } else if (totalHours > 0) {
      return "in ${totalHours}h ${_remainingTime.inMinutes.remainder(60)}m";
    } else if (totalMinutes > 0) {
      return "in ${totalMinutes}m";
    } else if (totalSeconds > 0) {
      return "in ${totalSeconds}s";
    } else {
      return "starting now";
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF7553F6);
    final backgroundColor = widget.backgroundColor ?? Colors.grey[100]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isComplete ? Colors.green.withOpacity(0.1) : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isComplete 
              ? Colors.green.withOpacity(0.3)
              : primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            widget.label,
            style: widget.labelStyle ?? TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isComplete ? Colors.green[700] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Countdown Display
          if (!_isComplete) ...[
            Text(
              _formatDuration(_remainingTime),
              style: widget.textStyle ?? TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: primaryColor,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              _getTimeLabel(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Session Started!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CompactCountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final Color? primaryColor;
  final double? fontSize;
  final VoidCallback? onComplete;

  const CompactCountdownTimer({
    super.key,
    required this.targetTime,
    this.primaryColor,
    this.fontSize = 14,
    this.onComplete,
  });

  @override
  State<CompactCountdownTimer> createState() => _CompactCountdownTimerState();
}

class _CompactCountdownTimerState extends State<CompactCountdownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      setState(() {
        _remainingTime = widget.targetTime.difference(now);
        _isComplete = false;
      });
    } else {
      setState(() {
        _remainingTime = Duration.zero;
        _isComplete = true;
      });
      
      if (!_isComplete) {
        widget.onComplete?.call();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
      
      if (_isComplete) {
        timer.cancel();
      }
    });
  }

  String _formatCompactDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return "Started";
    }

    final totalMinutes = duration.inMinutes;
    final totalHours = duration.inHours;
    final totalDays = duration.inDays;

    if (totalDays > 0) {
      return "${totalDays}d ${duration.inHours.remainder(24)}h";
    } else if (totalHours > 0) {
      return "${totalHours}h ${duration.inMinutes.remainder(60)}m";
    } else if (totalMinutes > 0) {
      return "${totalMinutes}m";
    } else {
      return "${duration.inSeconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF7553F6);

    if (_isComplete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle,
            color: Colors.green,
            size: widget.fontSize! + 2,
          ),
          const SizedBox(width: 4),
          Text(
            "Live",
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          color: primaryColor,
          size: widget.fontSize! + 2,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCompactDuration(_remainingTime),
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class SessionStatusIndicator extends StatelessWidget {
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final String status;
  final double? size;

  const SessionStatusIndicator({
    super.key,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.status,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    Color color;
    IconData icon;
    String label;

    if (status == 'ongoing' || (now.isAfter(scheduledStartTime) && now.isBefore(scheduledEndTime))) {
      color = Colors.green;
      icon = Icons.play_circle;
      label = 'Live';
    } else if (status == 'completed' || now.isAfter(scheduledEndTime)) {
      color = Colors.grey;
      icon = Icons.check_circle;
      label = 'Ended';
    } else if (status == 'cancelled') {
      color = Colors.red;
      icon = Icons.cancel;
      label = 'Cancelled';
    } else {
      color = const Color(0xFF7553F6);
      icon = Icons.schedule;
      label = 'Scheduled';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: size! - 2,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}