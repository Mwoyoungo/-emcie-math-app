import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/course.dart';
import '../../services/chat_session_service.dart';
import '../../services/performance_service.dart';
import '../../services/user_service.dart';
import 'components/topic_tile.dart';
import 'components/secondary_course_card.dart';
import '../test/image_upload_test_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                      "Math Topics",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                              color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // 2-Column Grid Layout for CAPS Topics
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
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        // Get real data from services
                        final hasActiveSession = user != null &&
                            chatSessionService.hasSessionForTopic(
                                user.email, course.title);
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
                            
                            return TopicTile(
                              title: course.title,
                              description: course.description,
                              color: course.color,
                              iconSrc: course.iconSrc,
                              progress: progress,
                              badge: badge,
                              hasActiveSession: hasActiveSession,
                              questionsAsked: questionsAsked,
                              correctAnswers: topicPerformance?.correctAnswers ?? 0,
                              wrongAnswers: topicPerformance?.wrongAnswers ?? 0,
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImageUploadTestScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF7553F6),
            child: const Icon(Icons.image, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildContinueLearningSection(
      BuildContext context,
      ChatSessionService chatSessionService,
      PerformanceService performanceService,
      user) {
    if (user == null) return const SizedBox();

    final activeSessions = chatSessionService.getSessionsForUser(user.email);

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
          final course = courses.firstWhere(
            (c) => c.title == session.topicTitle,
            orElse: () => courses.first,
          );

          return Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: SecondaryCourseCard(
              title: "${course.title} - ${session.messages.length} messages",
              iconsSrc: course.iconSrc,
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
