import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/performance_service.dart';
import '../../../services/user_service.dart';

class PerformanceStats extends StatelessWidget {
  const PerformanceStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PerformanceService, UserService>(
      builder: (context, performanceService, userService, child) {
        final overallPerformance = performanceService.getOverallPerformance();
        final user = userService.currentUser;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage("assets/avaters/Avatar Default.jpg"),
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? "Student",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Poppins",
                          ),
                        ),
                        Text(
                          "${userService.gradeDisplay} • Mathematics",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7553F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPerformanceBadge(overallPerformance['accuracyPercentage']),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7553F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Topics Studied",
                      "${overallPerformance['topicsStudied']}",
                      "subjects",
                      const Color(0xFF4ECDC4),
                      Icons.subject,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Correct Answers",
                      "${overallPerformance['correctAnswers']}",
                      "right",
                      const Color(0xFF4CAF50),
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Accuracy",
                      "${overallPerformance['accuracyPercentage'].toStringAsFixed(1)}%",
                      "correct",
                      const Color(0xFF80A4FF),
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Total Questions",
                      "${overallPerformance['totalQuestions']}",
                      "answered", 
                      const Color(0xFF9CC5FF),
                      Icons.quiz,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPerformanceBadge(double accuracy) {
    if (accuracy >= 90) return "🏆 Excellent";
    if (accuracy >= 80) return "🥇 Great";
    if (accuracy >= 70) return "🥈 Good";
    if (accuracy >= 60) return "🥉 Fair";
    if (accuracy > 0) return "📚 Learning";
    return "🌟 Getting Started";
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: "Poppins",
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}