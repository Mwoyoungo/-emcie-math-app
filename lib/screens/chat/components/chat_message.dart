import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:io';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasLatex;
  final String? imagePath;
  final String? chatMessageId;
  final String? executionId;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasLatex = false,
    this.imagePath,
    this.chatMessageId,
    this.executionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'hasLatex': hasLatex,
      'imagePath': imagePath,
      'chatMessageId': chatMessageId,
      'executionId': executionId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      hasLatex: json['hasLatex'] ?? false,
      imagePath: json['imagePath'],
      chatMessageId: json['chatMessageId'],
      executionId: json['executionId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7553F6).withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/avaters/Avatar 2.jpg"),
                        radius: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                colors: [Color(0xFF7553F6), Color(0xFF9575CD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Colors.white, Color(0xFFF8F9FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: isUser
                              ? const Radius.circular(24)
                              : const Radius.circular(6),
                          bottomRight: isUser
                              ? const Radius.circular(6)
                              : const Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isUser
                                ? const Color(0xFF7553F6).withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser && !hasLatex)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7553F6)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "🌟 Mam Rose",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7553F6),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (imagePath != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(imagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (hasLatex && !isUser)
                            _buildLatexText()
                          else
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: 16,
                                color: isUser ? Colors.white : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          if (isUser) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7553F6).withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/avaters/Avatar Default.jpg"),
                        radius: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLatexText() {
    // Process text to handle multiple LaTeX formats
    String processedText = _preprocessLatexText(text);

    // Split text by LaTeX expressions and render them appropriately
    final parts = <Widget>[];

    // Simplified regex patterns - process each type separately
    List<RegExp> latexPatterns = [
      RegExp(r'\$\$([^$]+)\$\$'), // Display math $$...$$
      RegExp(r'\$([^$]+)\$'), // Inline math $...$
    ];

    String remainingText = processedText;

    while (remainingText.isNotEmpty) {
      RegExpMatch? earliestMatch;
      bool isDisplayMode = false;

      // Find the earliest LaTeX match
      for (var pattern in latexPatterns) {
        var match = pattern.firstMatch(remainingText);
        if (match != null &&
            (earliestMatch == null || match.start < earliestMatch.start)) {
          earliestMatch = match;
          isDisplayMode = pattern.pattern.contains('\$\$');
        }
      }

      if (earliestMatch == null) {
        // No more LaTeX found, add remaining text
        if (remainingText.trim().isNotEmpty) {
          parts.add(Text(
            remainingText,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.3,
            ),
          ));
        }
        break;
      }

      // Add text before LaTeX
      if (earliestMatch.start > 0) {
        String beforeText = remainingText.substring(0, earliestMatch.start);
        if (beforeText.trim().isNotEmpty) {
          parts.add(Text(
            beforeText,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.3,
            ),
          ));
        }
      }

      // Add LaTeX expression
      String latexContent = earliestMatch.group(1) ?? '';
      if (latexContent.isNotEmpty) {
        try {
          parts.add(Container(
            margin:
                isDisplayMode ? const EdgeInsets.symmetric(vertical: 8) : null,
            child: Math.tex(
              latexContent,
              textStyle: TextStyle(
                fontSize: isDisplayMode ? 18 : 16,
                color: Colors.black87,
              ),
              mathStyle: isDisplayMode ? MathStyle.display : MathStyle.text,
            ),
          ));
        } catch (e) {
          // Fallback to regular text if LaTeX parsing fails
          parts.add(Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              earliestMatch.group(0)!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ));
        }
      }

      // Move to text after this match
      remainingText = remainingText.substring(earliestMatch.end);
    }

    // If no LaTeX was found, just return regular text
    if (parts.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.3,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts
          .map((part) => SizedBox(
                width: double.infinity,
                child: part,
              ))
          .toList(),
    );
  }

  String _preprocessLatexText(String input) {
    // Convert common markdown LaTeX to proper LaTeX delimiters
    String processed = input;

    // Simple string replacements to avoid complex regex
    // Convert common LaTeX delimiters
    processed = processed.replaceAll('\\(', '\$');
    processed = processed.replaceAll('\\)', '\$');
    processed = processed.replaceAll('\\[', '\$\$');
    processed = processed.replaceAll('\\]', '\$\$');

    // Handle simple fractions like "1/2", "3/4" etc.
    processed = processed.replaceAllMapped(
      RegExp(r'\b(\d+)/(\d+)\b'),
      (match) => '\$\\frac{${match.group(1)}}{${match.group(2)}}\$',
    );

    // Handle mathematical operators and symbols
    processed = processed.replaceAll('×', '\\times');
    processed = processed.replaceAll('÷', '\\div');
    processed = processed.replaceAll('≤', '\\leq');
    processed = processed.replaceAll('≥', '\\geq');
    processed = processed.replaceAll('≠', '\\neq');
    processed = processed.replaceAll('∞', '\\infty');
    processed = processed.replaceAll('π', '\\pi');
    processed = processed.replaceAll('∑', '\\sum');
    processed = processed.replaceAll('∫', '\\int');

    return processed;
  }
}
