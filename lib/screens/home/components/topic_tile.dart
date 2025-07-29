import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../chat/chat_screen.dart';

class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.title,
    required this.description,
    this.color = const Color(0xFF7553F6),
    this.iconSrc = "assets/icons/ios.svg",
    this.progress = 0.0,
    this.badge,
    this.hasActiveSession = false,
    this.questionsAsked = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
  });

  final String title, description, iconSrc;
  final Color color;
  final double progress; // 0.0 to 1.0
  final String? badge; // "Gold", "Silver", "Bronze"
  final bool hasActiveSession;
  final int questionsAsked, correctAnswers, wrongAnswers;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(topicTitle: title),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          iconSrc,
                          width: 20,
                          height: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (hasActiveSession)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (badge != null) _buildBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: "Poppins",
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Performance statistics
            if (questionsAsked > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatChip(
                    "$questionsAsked Q",
                    Colors.white.withOpacity(0.3),
                    Colors.white,
                  ),
                  const SizedBox(width: 4),
                  _buildStatChip(
                    "✓ $correctAnswers",
                    const Color(0xFF4CAF50).withOpacity(0.3),
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 4),
                  _buildStatChip(
                    "✗ $wrongAnswers",
                    const Color(0xFFFF5252).withOpacity(0.3),
                    const Color(0xFFFF5252),
                  ),
                ],
              ),
            ],
            if (progress > 0) ...[
              const SizedBox(height: 8),
              _buildProgressBar(),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasActiveSession ? "CONTINUE" : "START LEARNING",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    Color badgeColor;
    String badgeIcon;
    
    switch (badge) {
      case "Gold":
        badgeColor = const Color(0xFFFFD700);
        badgeIcon = "🏆";
        break;
      case "Silver":
        badgeColor = const Color(0xFFC0C0C0);
        badgeIcon = "🥈";
        break;
      case "Bronze":
        badgeColor = const Color(0xFFCD7F32);
        badgeIcon = "🥉";
        break;
      default:
        badgeColor = Colors.white;
        badgeIcon = "⭐";
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        "$badgeIcon $badge",
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progress",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "${(progress * 100).round()}%",
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}