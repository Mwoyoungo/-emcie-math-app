import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopicProgressCard extends StatelessWidget {
  final String topicTitle;
  final int totalQuestions;
  final int correctAnswers;
  final Color color;
  final String iconSrc;

  const TopicProgressCard({
    super.key,
    required this.topicTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.color,
    required this.iconSrc,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).round() : 0;
    final incorrectAnswers = totalQuestions - correctAnswers;
    final hasActivity = totalQuestions > 0;
    
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconSrc,
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topicTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                    if (hasActivity) _buildPerformanceBadge(accuracy),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasActivity) ...[
                  Row(
                    children: [
                      _buildStatChip(
                        "$correctAnswers correct",
                        const Color(0xFF4ECDC4),
                        Icons.check,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        "$incorrectAnswers wrong",
                        const Color(0xFFFF6B6B),
                        Icons.close,
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Start practicing to see your progress!",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: hasActivity ? correctAnswers / totalQuestions : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hasActivity ? "$correctAnswers / $totalQuestions" : "0 / 0",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge(int accuracy) {
    Color badgeColor;
    String badgeText;
    
    if (accuracy >= 90) {
      badgeColor = const Color(0xFF4ECDC4);
      badgeText = "🏆 Gold";
    } else if (accuracy >= 75) {
      badgeColor = const Color(0xFF80A4FF);  
      badgeText = "🥈 Silver";
    } else if (accuracy >= 60) {
      badgeColor = const Color(0xFFFF6B6B);
      badgeText = "🥉 Bronze";
    } else {
      badgeColor = Colors.grey;
      badgeText = "📚 Practice";
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}