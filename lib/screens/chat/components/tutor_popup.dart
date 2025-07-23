import 'package:flutter/material.dart';

enum TutorTriggerType {
  wrongAnswers,
  gamifiedBadge,
  keywordDetected,
  callButton,
}

enum TutorSessionType {
  quickHelp,
  deepSession,
}

class TutorPopup extends StatefulWidget {
  final TutorTriggerType triggerType;
  final String topicTitle;
  final Function(TutorSessionType) onBookingRequested;

  const TutorPopup({
    super.key,
    required this.triggerType,
    required this.topicTitle,
    required this.onBookingRequested,
  });

  @override
  State<TutorPopup> createState() => _TutorPopupState();
}

class _TutorPopupState extends State<TutorPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTitleForTrigger() {
    switch (widget.triggerType) {
      case TutorTriggerType.wrongAnswers:
        return "Need Extra Help? 🤔";
      case TutorTriggerType.gamifiedBadge:
        return "🎉 Badge Unlocked! Get Tutor Help";
      case TutorTriggerType.keywordDetected:
        return "Looking for Help? 💡";
      case TutorTriggerType.callButton:
        return "Get Professional Tutor Help 📚";
    }
  }

  String _getMessageForTrigger() {
    switch (widget.triggerType) {
      case TutorTriggerType.wrongAnswers:
        return "I noticed you're having some challenges with ${widget.topicTitle}. Would you like to connect with a professional tutor for personalized help?";
      case TutorTriggerType.gamifiedBadge:
        return "Great job completing 3 questions! 🌟 You've earned access to our professional tutors. Ready to take your learning to the next level?";
      case TutorTriggerType.keywordDetected:
        return "It seems you're looking for additional support with ${widget.topicTitle}. Our expert tutors are here to help you succeed!";
      case TutorTriggerType.callButton:
        return "Connect with our expert tutors for personalized ${widget.topicTitle} assistance. Choose the session type that works best for you!";
    }
  }

  Widget _getBadgeIcon() {
    switch (widget.triggerType) {
      case TutorTriggerType.wrongAnswers:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.help_outline,
            color: Color(0xFFFF6B6B),
            size: 32,
          ),
        );
      case TutorTriggerType.gamifiedBadge:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(
            Icons.stars,
            color: Colors.white,
            size: 32,
          ),
        );
      case TutorTriggerType.keywordDetected:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF4ECDC4),
            size: 32,
          ),
        );
      case TutorTriggerType.callButton:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7553F6).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school,
            color: Color(0xFF7553F6),
            size: 32,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge/Icon
                    _getBadgeIcon(),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      _getTitleForTrigger(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: "Poppins",
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      _getMessageForTrigger(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Session Options
                    Row(
                      children: [
                        Expanded(
                          child: _buildSessionOption(
                            title: "Quick Help",
                            subtitle: "5-10 minutes",
                            price: "\$8",
                            color: const Color(0xFF4ECDC4),
                            icon: Icons.flash_on,
                            sessionType: TutorSessionType.quickHelp,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSessionOption(
                            title: "Deep Session",
                            subtitle: "30-60 minutes",
                            price: "\$25-50",
                            color: const Color(0xFF7553F6),
                            icon: Icons.psychology,
                            sessionType: TutorSessionType.deepSession,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Close button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Maybe Later",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionOption({
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required IconData icon,
    required TutorSessionType sessionType,
  }) {
    return InkWell(
      onTap: () => widget.onBookingRequested(sessionType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}