import 'package:flutter/foundation.dart';

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
  final Map<String, TopicPerformance> _topicPerformances = {};
  
  Map<String, TopicPerformance> get topicPerformances => Map.unmodifiable(_topicPerformances);

  // Track a question result
  void recordQuestionResult({
    required String topicTitle,
    required String questionText,
    required String userAnswer,
    required String aiResponse,
    required String executionId,
  }) {
    // Parse AI response to determine if answer is correct
    final isCorrect = _parseCorrectness(aiResponse);
    
    final result = QuestionResult(
      questionText: questionText,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
      topicTitle: topicTitle,
      executionId: executionId,
    );

    // Get or create topic performance
    if (!_topicPerformances.containsKey(topicTitle)) {
      _topicPerformances[topicTitle] = TopicPerformance(
        topicTitle: topicTitle,
        results: [],
      );
    }

    // Add result to topic performance
    final updatedResults = List<QuestionResult>.from(_topicPerformances[topicTitle]!.results);
    updatedResults.add(result);
    
    _topicPerformances[topicTitle] = TopicPerformance(
      topicTitle: topicTitle,
      results: updatedResults,
    );

    debugPrint('📊 Recorded ${isCorrect ? "CORRECT" : "WRONG"} answer for $topicTitle');
    debugPrint('📈 Topic stats: ${_topicPerformances[topicTitle]!.correctAnswers}/${_topicPerformances[topicTitle]!.totalQuestions} (${_topicPerformances[topicTitle]!.accuracyPercentage.toStringAsFixed(1)}%)');
    
    notifyListeners();
  }

  // Parse AI response to determine correctness
  bool _parseCorrectness(String aiResponse) {
    final upperResponse = aiResponse.toUpperCase();
    
    // Look for [CORRECT] or [WRONG] in the response
    if (upperResponse.contains('[CORRECT]') || upperResponse.contains('CORRECT')) {
      return true;
    }
    if (upperResponse.contains('[WRONG]') || upperResponse.contains('WRONG')) {
      return false;
    }
    
    // Fallback: look for positive/negative indicators
    if (upperResponse.contains('WELL DONE') || 
        upperResponse.contains('EXCELLENT') || 
        upperResponse.contains('PERFECT') ||
        upperResponse.contains('GREAT JOB') ||
        upperResponse.contains('THAT\'S RIGHT') ||
        upperResponse.contains('EXACTLY')) {
      return true;
    }
    
    if (upperResponse.contains('INCORRECT') || 
        upperResponse.contains('NOT QUITE') || 
        upperResponse.contains('TRY AGAIN') ||
        upperResponse.contains('ALMOST') ||
        upperResponse.contains('CLOSE, BUT')) {
      return false;
    }
    
    // If we can't determine, assume it's informational (not a question result)
    return false;
  }

  // Get performance for a specific topic
  TopicPerformance? getTopicPerformance(String topicTitle) {
    return _topicPerformances[topicTitle];
  }

  // Get overall performance across all topics
  Map<String, dynamic> getOverallPerformance() {
    if (_topicPerformances.isEmpty) {
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
    
    for (final performance in _topicPerformances.values) {
      totalQuestions += performance.totalQuestions;
      correctAnswers += performance.correctAnswers;
    }

    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': totalQuestions - correctAnswers,
      'accuracyPercentage': totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0,
      'topicsStudied': _topicPerformances.length,
    };
  }

  // Check if there are any results for a topic
  bool hasPerformanceData(String topicTitle) {
    return _topicPerformances.containsKey(topicTitle) && 
           _topicPerformances[topicTitle]!.totalQuestions > 0;
  }

  // Get recent performance (last 10 questions across all topics)
  List<QuestionResult> getRecentPerformance() {
    final allResults = <QuestionResult>[];
    
    for (final performance in _topicPerformances.values) {
      allResults.addAll(performance.results);
    }
    
    allResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allResults.take(10).toList();
  }

  // Clear all performance data
  void clearAllPerformance() {
    _topicPerformances.clear();
    debugPrint('🗑️ Cleared all performance data');
    notifyListeners();
  }

  // Clear performance for specific topic
  void clearTopicPerformance(String topicTitle) {
    _topicPerformances.remove(topicTitle);
    debugPrint('🗑️ Cleared performance data for $topicTitle');
    notifyListeners();
  }
}