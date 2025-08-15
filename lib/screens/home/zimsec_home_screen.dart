import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/zimsec_course.dart';
import '../../services/chat_session_service.dart';
import '../../services/performance_service.dart';
import '../../services/user_service.dart';
import '../../services/supabase_service.dart';
import '../chat/chat_screen.dart';
import '../chat/components/chat_message.dart';
import 'components/secondary_course_card.dart';

class ZimsecHomePage extends StatelessWidget {
  const ZimsecHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatSessionService, PerformanceService, UserService>(
      builder: (context, chatSessionService, performanceService, userService,
          child) {
        final user = userService.currentUser;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${userService.firstName}! 🇿🇼',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                            color: Color(0xFF0F0826),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ready to tackle Form ${user?.grade} ZIMSEC Mathematics?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: "Poppins",
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ZIMSEC Mathematics Topics",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Poppins",
                            color: Color(0xFF0F0826),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: ZimsecCourses.courses.length,
                          itemBuilder: (context, index) {
                            final course = ZimsecCourses.courses[index];
                            return _buildZimsecTopicCard(
                              context,
                              course,
                              chatSessionService,
                              performanceService,
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZimsecTopicCard(
    BuildContext context,
    ZimsecCourse course,
    ChatSessionService chatSessionService,
    PerformanceService performanceService,
  ) {
    return GestureDetector(
      onTap: () => _navigateToZimsecTopic(context, course, chatSessionService),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [course.color.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: course.color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: course.color.withValues(alpha: 0.1),
              offset: const Offset(0, 8),
              blurRadius: 20,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: course.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: course.color.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  course.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Poppins",
                  color: Color(0xFF0F0826),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: course.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Start Learning',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: course.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToZimsecTopic(
    BuildContext context,
    ZimsecCourse course,
    ChatSessionService chatSessionService,
  ) {
    // Simply navigate to chat screen - let chat screen handle initialization like CAPS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(topicTitle: course.title),
      ),
    );
  }
}