import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/university_course.dart';
import '../../services/chat_session_service.dart';
import '../../services/performance_service.dart';
import '../../services/user_service.dart';
import '../../services/supabase_service.dart';
import '../chat/chat_screen.dart';
import '../chat/components/chat_message.dart';
import 'components/university_topic_tile.dart';
import 'components/secondary_course_card.dart';

class UniversityHomePage extends StatelessWidget {
  const UniversityHomePage({super.key});

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
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Literature Topics",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                              color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // 2-Column Grid Layout for University Topics
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: universityCourses.length,
                      itemBuilder: (context, index) {
                        final course = universityCourses[index];

                        // Get real data from services
                        final userId = user != null ? 
                            (SupabaseService.instance.client.auth.currentUser?.id ?? user.email) : 
                            null;
                        final hasActiveSession = userId != null &&
                            chatSessionService.hasSessionForTopic(
                                userId, course.title);
                        final topicPerformance = performanceService
                            .getTopicPerformance(course.title);

                        // Calculate progress based on performance
                        double progress = 0.0;
                        String? badge;

                        if (topicPerformance != null &&
                            topicPerformance.totalQuestions > 0) {
                          progress =
                              topicPerformance.accuracyPercentage / 100.0;
                          badge = _getPerformanceBadge(
                              topicPerformance.accuracyPercentage);
                        }

                        return FutureBuilder<int>(
                          future: performanceService.getQuestionsAsked(course.title),
                          builder: (context, questionsSnapshot) {
                            final questionsAsked = questionsSnapshot.data ?? 0;
                            
                            return UniversityTopicTile(
                              title: course.title,
                              description: course.description,
                              color: course.color,
                              icon: course.icon,
                              progress: progress,
                              badge: badge,
                              hasActiveSession: hasActiveSession,
                              questionsAsked: questionsAsked,
                              correctAnswers: topicPerformance?.correctAnswers ?? 0,
                              wrongAnswers: topicPerformance?.wrongAnswers ?? 0,
                              onTap: () => _startUniversityAssessment(context, course, user),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Continue Learning Section - show only topics with active sessions
                  _buildContinueLearningSection(
                      context, chatSessionService, performanceService, user),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startUniversityAssessment(BuildContext context, UniversityCourse course, user) async {
    if (user == null) return;

    try {
      // Get or create chat session
      final chatSessionService = Provider.of<ChatSessionService>(context, listen: false);
      
      // Get proper user ID for database integration
      final userId = SupabaseService.instance.client.auth.currentUser?.id ?? user.email;
      
      ChatSession session;
      if (chatSessionService.hasSessionForTopic(userId, course.title)) {
        // Resume existing session
        session = (await chatSessionService.resumeSession(
          userId: userId,
          topicTitle: course.title,
        ))!;
      } else {
        // Create new session
        session = await chatSessionService.createNewSession(
          userId: userId,
          topicTitle: course.title,
          grade: user.grade,
        );
        
        // Add automated initial message
        final initialMessage = ChatMessage(
          text: "Please assess me on ${course.title.toLowerCase()}",
          isUser: true,
          timestamp: DateTime.now(),
        );
        await chatSessionService.addMessage(initialMessage);
      }

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              topicTitle: course.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildContinueLearningSection(
      BuildContext context,
      ChatSessionService chatSessionService,
      PerformanceService performanceService,
      user) {
    if (user == null) return const SizedBox();

    final userId = SupabaseService.instance.client.auth.currentUser?.id ?? user.email;
    final activeSessions = chatSessionService.getSessionsForUser(userId);

    if (activeSessions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "Continue Learning",
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        ...activeSessions.take(3).map((session) {
          final course = universityCourses.firstWhere(
            (c) => c.title == session.topicTitle,
            orElse: () => universityCourses.first,
          );

          return Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: SecondaryCourseCard(
              title: "${course.title} - ${session.messages.length} messages",
              iconsSrc: "assets/icons/code.svg", // Use existing icon
              colorl: course.color,
            ),
          );
        }),
      ],
    );
  }

  String? _getPerformanceBadge(double accuracy) {
    if (accuracy >= 90) return "Gold";
    if (accuracy >= 75) return "Silver";
    if (accuracy >= 60) return "Bronze";
    return null;
  }
}