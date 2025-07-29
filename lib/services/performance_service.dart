import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class QuestionResult {
  final String questionText;
  final String userAnswer;
  final bool isCorrect;
  final DateTime timestamp;
  final String topicTitle;
  final String executionId;

  QuestionResult({
    required this.questionText,
    required this.userAnswer,
    required this.isCorrect,
    required this.timestamp,
    required this.topicTitle,
    required this.executionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timestamp': timestamp.toIso8601String(),
      'topicTitle': topicTitle,
      'executionId': executionId,
    };
  }

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionText: json['questionText'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      topicTitle: json['topicTitle'] ?? '',
      executionId: json['executionId'] ?? '',
    );
  }
}

class TopicPerformance {
  final String topicTitle;
  final List<QuestionResult> results;
  
  TopicPerformance({
    required this.topicTitle,
    required this.results,
  });

  int get totalQuestions => results.length;
  int get correctAnswers => results.where((r) => r.isCorrect).length;
  int get wrongAnswers => results.where((r) => !r.isCorrect).length;
  
  double get accuracyPercentage {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  String get performanceGrade {
    final accuracy = accuracyPercentage;
    if (accuracy >= 90) return 'A+';
    if (accuracy >= 80) return 'A';
    if (accuracy >= 70) return 'B';
    if (accuracy >= 60) return 'C';
    if (accuracy >= 50) return 'D';
    return 'F';
  }

  Map<String, dynamic> toJson() {
    return {
      'topicTitle': topicTitle,
      'results': results.map((r) => r.toJson()).toList(),
    };
  }

  factory TopicPerformance.fromJson(Map<String, dynamic> json) {
    return TopicPerformance(
      topicTitle: json['topicTitle'] ?? '',
      results: (json['results'] as List? ?? [])
          .map((r) => QuestionResult.fromJson(r))
          .toList(),
    );
  }
}

class PerformanceService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final Map<String, Map<String, dynamic>> _cachedStats = {}; // Cache for performance stats
  
  Map<String, TopicPerformance> get topicPerformances => {}; // Kept for compatibility

  // Track every AI message as a question asked (now uses database)
  Future<void> recordAIMessage({
    required String topicTitle,
    required String aiResponse,
    required String executionId,
    String userAnswer = '',
  }) async {
    try {
      final result = await _supabaseService.recordAIMessage(
        topicTitle: topicTitle,
        aiResponse: aiResponse,
        executionId: executionId,
        userAnswer: userAnswer,
      );

      if (result['success'] == true) {
        // Clear cache for this topic to force refresh on next access
        _cachedStats.remove(topicTitle);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error recording AI message: $e');
    }
  }

  // Get total questions asked (AI messages) for a topic
  Future<int> getQuestionsAsked(String topicTitle) async {
    try {
      final stats = await _getTopicStats(topicTitle);
      return stats['questionsAsked'] as int;
    } catch (e) {
      debugPrint('❌ Error getting questions asked: $e');
      return 0;
    }
  }

  // Synchronous version for compatibility (returns cached data or 0)
  int getQuestionsAskedSync(String topicTitle) {
    final cachedStats = _cachedStats[topicTitle];
    return cachedStats?['questionsAsked'] as int? ?? 0;
  }

  // Get cached or fetch topic statistics
  Future<Map<String, dynamic>> _getTopicStats(String topicTitle) async {
    // Return cached stats if available
    if (_cachedStats.containsKey(topicTitle)) {
      return _cachedStats[topicTitle]!;
    }

    // Fetch from database
    final stats = await _supabaseService.getTopicPerformanceStats(topicTitle);
    _cachedStats[topicTitle] = stats;
    return stats;
  }

  // Legacy method - now handled by recordAIMessage
  void recordQuestionResult({
    required String topicTitle,
    required String questionText,
    required String userAnswer,
    required String aiResponse,
    required String executionId,
  }) {
    // This method is now handled by recordAIMessage in the database
    // Keeping for backward compatibility but not used
    debugPrint('📊 Legacy recordQuestionResult called - use recordAIMessage instead');
  }

  // Get performance for a specific topic (async version for database)
  Future<TopicPerformance?> getTopicPerformanceAsync(String topicTitle) async {
    try {
      final stats = await _getTopicStats(topicTitle);
      if (stats['questionsAsked'] == 0) return null;

      // Create mock results for compatibility
      final results = <QuestionResult>[];
      final correctCount = stats['correctAnswers'] as int;
      final wrongCount = stats['wrongAnswers'] as int;

      // Add correct results
      for (int i = 0; i < correctCount; i++) {
        results.add(QuestionResult(
          questionText: 'Database question ${i + 1}',
          userAnswer: 'Correct answer',
          isCorrect: true,
          timestamp: DateTime.now(),
          topicTitle: topicTitle,
          executionId: 'db_$i',
        ));
      }

      // Add wrong results
      for (int i = 0; i < wrongCount; i++) {
        results.add(QuestionResult(
          questionText: 'Database question ${correctCount + i + 1}',
          userAnswer: 'Wrong answer',
          isCorrect: false,
          timestamp: DateTime.now(),
          topicTitle: topicTitle,
          executionId: 'db_wrong_$i',
        ));
      }

      return TopicPerformance(
        topicTitle: topicTitle,
        results: results,
      );
    } catch (e) {
      debugPrint('❌ Error getting topic performance: $e');
      return null;
    }
  }

  // Synchronous version for compatibility (returns cached data or null)
  TopicPerformance? getTopicPerformance(String topicTitle) {
    final cachedStats = _cachedStats[topicTitle];
    if (cachedStats == null || cachedStats['questionsAsked'] == 0) return null;

    // Create mock results from cached data
    final results = <QuestionResult>[];
    final correctCount = cachedStats['correctAnswers'] as int;
    final wrongCount = cachedStats['wrongAnswers'] as int;

    // Add correct results
    for (int i = 0; i < correctCount; i++) {
      results.add(QuestionResult(
        questionText: 'Cached question ${i + 1}',
        userAnswer: 'Correct answer',
        isCorrect: true,
        timestamp: DateTime.now(),
        topicTitle: topicTitle,
        executionId: 'cached_$i',
      ));
    }

    // Add wrong results
    for (int i = 0; i < wrongCount; i++) {
      results.add(QuestionResult(
        questionText: 'Cached question ${correctCount + i + 1}',
        userAnswer: 'Wrong answer',
        isCorrect: false,
        timestamp: DateTime.now(),
        topicTitle: topicTitle,
        executionId: 'cached_wrong_$i',
      ));
    }

    return TopicPerformance(
      topicTitle: topicTitle,
      results: results,
    );
  }

  // Get overall performance across all topics (database version)
  Future<Map<String, dynamic>> getOverallPerformance() async {
    try {
      final allStats = await _supabaseService.getAllTopicPerformanceStats();
      final performance = allStats['performance'] as List<Map<String, dynamic>>;
      
      if (performance.isEmpty) {
        return {
          'totalQuestions': 0,
          'correctAnswers': 0,
          'wrongAnswers': 0,
          'accuracyPercentage': 0.0,
          'topicsStudied': 0,
        };
      }

      int totalQuestions = 0;
      int correctAnswers = 0;
      
      for (final topicStats in performance) {
        totalQuestions += topicStats['questionsAsked'] as int;
        correctAnswers += topicStats['correctAnswers'] as int;
      }

      return {
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'wrongAnswers': totalQuestions - correctAnswers,
        'accuracyPercentage': totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0,
        'topicsStudied': performance.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting overall performance: $e');
      return {
        'totalQuestions': 0,
        'correctAnswers': 0,
        'wrongAnswers': 0,
        'accuracyPercentage': 0.0,
        'topicsStudied': 0,
      };
    }
  }

  // Check if there are any results for a topic (database version)
  Future<bool> hasPerformanceData(String topicTitle) async {
    try {
      final stats = await _getTopicStats(topicTitle);
      return stats['questionsAsked'] > 0;
    } catch (e) {
      debugPrint('❌ Error checking performance data: $e');
      return false;
    }
  }

  // Get recent performance (last 10 questions across all topics) - database version
  Future<List<QuestionResult>> getRecentPerformance() async {
    try {
      // This would require a database query to get recent results
      // For now, return empty list as this is not critical for basic functionality
      return <QuestionResult>[];
    } catch (e) {
      debugPrint('❌ Error getting recent performance: $e');
      return <QuestionResult>[];
    }
  }

  // Clear all performance data (cache only - database persists)
  void clearAllPerformance() {
    _cachedStats.clear();
    debugPrint('🗑️ Cleared cached performance data');
    notifyListeners();
  }

  // Clear performance for specific topic (cache only - database persists)
  void clearTopicPerformance(String topicTitle) {
    _cachedStats.remove(topicTitle);
    debugPrint('🗑️ Cleared cached performance data for $topicTitle');
    notifyListeners();
  }
}