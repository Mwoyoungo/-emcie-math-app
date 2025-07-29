import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/topic_progress_card.dart';
import 'components/performance_stats.dart';
import '../../services/performance_service.dart';
import '../../utils/responsive_utils.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      body: SafeArea(
        bottom: false,
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 40,
                  tablet: 32,
                  desktop: 24,
                )),
                Padding(
                  padding: ResponsiveUtils.getContentPadding(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Progress",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.black, 
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getScaledFontSize(context, 28),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _showLogoutDialog(context);
                          },
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'Logout',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Performance Stats Section
                const PerformanceStats(),
                
                Padding(
                  padding: ResponsiveUtils.getContentPadding(context),
                  child: Text(
                    "Topic Performance",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getScaledFontSize(context, 22),
                    ),
                  ),
                ),
                
                // Responsive Topic Progress Cards
                _buildResponsiveTopicGrid(context),
                
                SizedBox(height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 100,
                  tablet: 60,
                  desktop: 40,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveTopicGrid(BuildContext context) {
    return Consumer<PerformanceService>(
      builder: (context, performanceService, child) {
        // CAPS Mathematics Topics for Grade 10-12
        final topics = [
          {'title': 'Functions (Linear, Quadratic, Exponential & Trigonometric)', 'color': const Color(0xFF7553F6), 'icon': 'assets/icons/code.svg'},
          {'title': 'Number Patterns, Sequences & Series', 'color': const Color(0xFF80A4FF), 'icon': 'assets/icons/ios.svg'},
          {'title': 'Algebra (Equations, Inequalities & Manipulation)', 'color': const Color(0xFF9CC5FF), 'icon': 'assets/icons/code.svg'},
          {'title': 'Finance, Growth & Decay', 'color': const Color(0xFFFF6B6B), 'icon': 'assets/icons/ios.svg'},
          {'title': 'Trigonometry', 'color': const Color(0xFF4ECDC4), 'icon': 'assets/icons/code.svg'},
          {'title': 'Analytical Geometry', 'color': const Color(0xFFFFB74D), 'icon': 'assets/icons/ios.svg'},
          {'title': 'Statistics', 'color': const Color(0xFFE57373), 'icon': 'assets/icons/code.svg'},
          {'title': 'Probability', 'color': const Color(0xFF81C784), 'icon': 'assets/icons/ios.svg'},
          {'title': 'Calculus', 'color': const Color(0xFFBA68C8), 'icon': 'assets/icons/code.svg'},
          {'title': 'Euclidean Geometry', 'color': const Color(0xFF4DB6AC), 'icon': 'assets/icons/ios.svg'},
        ];

        // For mobile: single column
        if (ResponsiveUtils.isMobile(context)) {
          return Column(
            children: topics.map((topic) {
              final topicTitle = topic['title'] as String;
              final performance = performanceService.getTopicPerformance(topicTitle);
              
              return TopicProgressCard(
                topicTitle: topicTitle,
                totalQuestions: performance?.totalQuestions ?? 0,
                correctAnswers: performance?.correctAnswers ?? 0,
                color: topic['color'] as Color,
                iconSrc: topic['icon'] as String,
              );
            }).toList(),
          );
        }

        // For tablet/desktop: responsive grid
        final columns = ResponsiveUtils.getGridColumns(context);
        final padding = ResponsiveUtils.getContentPadding(context);
        
        return Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
              
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: topics.map((topic) {
                  final topicTitle = topic['title'] as String;
                  final performance = performanceService.getTopicPerformance(topicTitle);
                  
                  return SizedBox(
                    width: cardWidth,
                    child: TopicProgressCard(
                      topicTitle: topicTitle,
                      totalQuestions: performance?.totalQuestions ?? 0,
                      correctAnswers: performance?.correctAnswers ?? 0,
                      color: topic['color'] as Color,
                      iconSrc: topic['icon'] as String,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen and clear all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}