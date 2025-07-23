import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'components/chat_message.dart';
import 'components/math_input_bar.dart';
import 'components/tutor_popup.dart';
import '../../services/ai_service.dart';
import '../../services/user_service.dart';
import '../../services/chat_session_service.dart';
import '../../services/performance_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/responsive_utils.dart';

class ChatScreen extends StatefulWidget {
  final String topicTitle;
  
  const ChatScreen({super.key, required this.topicTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<ChatMessage> messages = [];
  bool _isInitialized = false;
  bool _isRoseThinking = false;
  int _consecutiveWrongAnswers = 0;
  int _totalQuestionsAsked = 0;

  @override
  void initState() {
    super.initState();
    // Initialize chat session and AI assessment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatSession();
    });
  }

  Future<void> _initializeChatSession() async {
    if (_isInitialized) return;
    
    final userService = Provider.of<UserService>(context, listen: false);
    final chatSessionService = Provider.of<ChatSessionService>(context, listen: false);
    final user = userService.currentUser;
    
    if (user == null || !mounted) return;
    
    await chatSessionService.initialize();
    
    // Initializing chat session for topic: ${widget.topicTitle}
    // Session summary: ${chatSessionService.getSessionSummary()}
    
    // Try to resume existing session first
    // Get proper user ID for database integration
    final userId = SupabaseService.instance.client.auth.currentUser?.id ?? user.email;
    
    final existingSession = await chatSessionService.resumeSession(
      userId: userId,
      topicTitle: widget.topicTitle,
    );
    
    if (existingSession != null && mounted) {
      // Load existing conversation
      // Resuming session with ${existingSession.messages.length} messages
      setState(() {
        messages = List.from(existingSession.messages);
        _isInitialized = true;
      });
      _scrollToBottom();
    } else {
      // Create new session and start AI assessment
      // Creating new session for topic: ${widget.topicTitle}
      final newSession = await chatSessionService.createNewSession(
        userId: userId,
        topicTitle: widget.topicTitle,
        grade: user.grade,
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        await _startAIAssessment(newSession.chatId);
      }
    }
  }

  Future<void> _startAIAssessment(String chatId) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final chatSessionService = Provider.of<ChatSessionService>(context, listen: false);
    final user = userService.currentUser;
    
    if (user == null || !mounted) return;

    // Show Rose is thinking loader
    if (mounted) {
      setState(() {
        _isRoseThinking = true;
      });
    }

    // Create the hidden initialization message
    final initMessage = AIService.createInitialAssessmentMessage(
      studentName: user.fullName,
      grade: "Grade ${user.grade}",
      subject: widget.topicTitle,
    );

    try {
      // Send initialization message to AI (this won't be shown to user)
      final aiResponse = await AIService.getAssessmentResponse(initMessage, chatId: chatId);
      
      // Check if widget is still mounted before calling setState
      if (mounted) {
        final aiMessage = ChatMessage(
          text: aiResponse.text,
          isUser: false,
          timestamp: DateTime.now(),
          hasLatex: _containsLatex(aiResponse.text),
          chatMessageId: aiResponse.chatMessageId,
          executionId: aiResponse.executionId,
        );
        
        setState(() {
          _isRoseThinking = false;
          messages.add(aiMessage);
        });
        
        // Save to session
        await chatSessionService.addMessage(aiMessage, executionId: aiResponse.executionId, aiChatId: aiResponse.chatId);
        _scrollToBottom();
      }
    } catch (e) {
      // Fallback welcome message
      if (mounted) {
        final fallbackMessage = ChatMessage(
          text: "Hi ${userService.firstName}! I'm Mam Rose, your AI math tutor! 🌟\n\nI'm ready to help you with ${widget.topicTitle} at your ${userService.gradeDisplay} level. Let's start with some assessment questions to understand your current knowledge!\n\nAre you ready to begin? 📚✨",
          isUser: false,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _isRoseThinking = false;
          messages.add(fallbackMessage);
        });
        
        await chatSessionService.addMessage(fallbackMessage);
        _scrollToBottom();
      }
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final chatSessionService = Provider.of<ChatSessionService>(context, listen: false);
    final performanceService = Provider.of<PerformanceService>(context, listen: false);
    final currentSession = chatSessionService.currentSession;
    
    if (currentSession == null) return;

    // Check for help keywords before processing
    _checkForHelpKeywords(text);

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    if (mounted) {
      setState(() {
        messages.add(userMessage);
      });
      _messageController.clear();
      _scrollToBottom();
    }
    
    // Save user message to session
    await chatSessionService.addMessage(userMessage);

    // Show Rose is thinking
    setState(() {
      _isRoseThinking = true;
    });

    // Get AI response
    try {
      final aiResponse = await AIService.getAssessmentResponse(text, chatId: currentSession.chatId);
      
      // Add AI response
      if (mounted) {
        final aiMessage = ChatMessage(
          text: aiResponse.text,
          isUser: false,
          timestamp: DateTime.now(),
          hasLatex: _containsLatex(aiResponse.text),
          chatMessageId: aiResponse.chatMessageId,
          executionId: aiResponse.executionId,
        );
        
        setState(() {
          _isRoseThinking = false;
          messages.add(aiMessage);
        });
        
        // Save AI message to session
        await chatSessionService.addMessage(aiMessage, executionId: aiResponse.executionId, aiChatId: aiResponse.chatId);
        
        // Track performance if AI response contains correctness feedback
        _trackPerformanceIfApplicable(text, aiResponse.text, aiResponse.executionId, performanceService);
        
        _scrollToBottom();
      }
    } catch (e) {
      // Fallback response
      if (mounted) {
        final fallbackMessage = ChatMessage(
          text: "I apologize, but I'm having trouble connecting right now. Let me try to help you with a practice question instead!\n\nCan you tell me more about what specific aspect of ${widget.topicTitle} you'd like to work on?",
          isUser: false,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _isRoseThinking = false;
          messages.add(fallbackMessage);
        });
        
        await chatSessionService.addMessage(fallbackMessage);
        _scrollToBottom();
      }
    }
  }

  // Keep the old static questions as fallback only

  void _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final chatSessionService = Provider.of<ChatSessionService>(context, listen: false);
      
      final imageMessage = ChatMessage(
        text: "I've received your image! Let me analyze this math problem for you...",
        isUser: false,
        imagePath: image.path,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        messages.add(imageMessage);
      });
      
      await chatSessionService.addMessage(imageMessage);
      _scrollToBottom();
      
      // Simulate analysis
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          final analysisMessage = ChatMessage(
            text: "I can see you've shared a problem! Based on what I can observe, let me help you work through this step by step. Could you also type out the specific question so I can provide the most accurate guidance?",
            isUser: false,
            timestamp: DateTime.now(),
          );
          
          setState(() {
            messages.add(analysisMessage);
          });
          
          await chatSessionService.addMessage(analysisMessage);
          _scrollToBottom();
        }
      });
    }
  }

  void _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      final chatSessionService = Provider.of<ChatSessionService>(context, listen: false);
      
      final photoMessage = ChatMessage(
        text: "Perfect! I can see your math problem.",
        isUser: false,
        imagePath: image.path,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        messages.add(photoMessage);
      });
      
      await chatSessionService.addMessage(photoMessage);
      _scrollToBottom();
    }
  }

  void _insertMathSymbol(String symbol) {
    final currentPosition = _messageController.selection.base.offset;
    final currentText = _messageController.text;
    final newText = currentText.substring(0, currentPosition) + 
                   symbol + 
                   currentText.substring(currentPosition);
    
    _messageController.text = newText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: currentPosition + symbol.length),
    );
  }

  bool _containsLatex(String text) {
    // Simplified LaTeX detection for common math formats
    return text.contains('\$') ||                          // Any $ delimiter
           text.contains('\\frac') ||                      // Fractions
           text.contains('\\sqrt') ||                      // Square roots
           text.contains('^') ||                           // Powers
           text.contains('_') ||                           // Subscripts
           text.contains('×') ||                           // Multiplication
           text.contains('÷') ||                           // Division
           text.contains('≤') || text.contains('≥') ||     // Inequalities
           text.contains('≠') ||                           // Not equal
           text.contains('∞') ||                           // Infinity
           text.contains('π') ||                           // Pi
           text.contains('√') ||                           // Square root symbol
           text.contains('∑') || text.contains('∫') ||     // Sum, integral
           text.contains('\\') && 
           (text.contains('alpha') || text.contains('beta') || 
            text.contains('gamma') || text.contains('theta') ||
            text.contains('sin') || text.contains('cos') || 
            text.contains('tan') || text.contains('log'));  // Greek letters and functions
  }

  void _trackPerformanceIfApplicable(String userAnswer, String aiResponse, String executionId, PerformanceService performanceService) {
    // Check if AI response contains correctness feedback
    final upperResponse = aiResponse.toUpperCase();
    final hasCorrectness = upperResponse.contains('[CORRECT]') || 
                          upperResponse.contains('[WRONG]') ||
                          upperResponse.contains('CORRECT') ||
                          upperResponse.contains('WRONG') ||
                          upperResponse.contains('WELL DONE') ||
                          upperResponse.contains('EXCELLENT') ||
                          upperResponse.contains('INCORRECT') ||
                          upperResponse.contains('NOT QUITE');

    if (hasCorrectness) {
      // Find the last AI question by looking through previous messages
      String questionText = '';
      for (int i = messages.length - 2; i >= 0; i--) {
        if (!messages[i].isUser && messages[i].text.contains('Question')) {
          questionText = messages[i].text;
          break;
        }
      }

      if (questionText.isNotEmpty) {
        performanceService.recordQuestionResult(
          topicTitle: widget.topicTitle,
          questionText: questionText,
          userAnswer: userAnswer,
          aiResponse: aiResponse,
          executionId: executionId,
        );

        // Track tutor triggers
        _totalQuestionsAsked++;
        final isCorrect = _parseCorrectness(aiResponse);
        
        if (isCorrect) {
          _consecutiveWrongAnswers = 0; // Reset counter on correct answer
        } else {
          _consecutiveWrongAnswers++;
          
          // Trigger tutor popup after 3 consecutive wrong answers
          if (_consecutiveWrongAnswers >= 3) {
            _showTutorPopup(TutorTriggerType.wrongAnswers);
            _consecutiveWrongAnswers = 0; // Reset to avoid repeated popups
          }
        }

        // Trigger gamified badge popup after 3 questions (regardless of correctness)
        if (_totalQuestionsAsked == 3) {
          _showTutorPopup(TutorTriggerType.gamifiedBadge);
        }
      }
    }
  }

  bool _parseCorrectness(String aiResponse) {
    final upperResponse = aiResponse.toUpperCase();
    
    // Look for positive indicators
    if (upperResponse.contains('[CORRECT]') || upperResponse.contains('CORRECT') ||
        upperResponse.contains('WELL DONE') || upperResponse.contains('EXCELLENT') ||
        upperResponse.contains('PERFECT') || upperResponse.contains('GREAT JOB') ||
        upperResponse.contains('THAT\'S RIGHT') || upperResponse.contains('EXACTLY')) {
      return true;
    }
    
    // Look for negative indicators
    if (upperResponse.contains('[WRONG]') || upperResponse.contains('WRONG') ||
        upperResponse.contains('INCORRECT') || upperResponse.contains('NOT QUITE') ||
        upperResponse.contains('TRY AGAIN') || upperResponse.contains('ALMOST')) {
      return false;
    }
    
    return false; // Default to false if unclear
  }

  void _showTutorPopup(TutorTriggerType triggerType) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TutorPopup(
        triggerType: triggerType,
        topicTitle: widget.topicTitle,
        onBookingRequested: (sessionType) {
          // Handle booking logic here
          Navigator.of(context).pop();
          _handleTutorBooking(sessionType);
        },
      ),
    );
  }

  void _checkForHelpKeywords(String text) {
    final lowerText = text.toLowerCase();
    final helpKeywords = [
      'help', 'stuck', 'confused', 'don\'t understand', 'difficult',
      'hard', 'tutor', 'explain', 'clarify', 'lost', 'need help',
      'struggling', 'can\'t solve', 'what does', 'how do i',
      'i need', 'assistance', 'support', 'guide me'
    ];

    for (final keyword in helpKeywords) {
      if (lowerText.contains(keyword)) {
        // Delay the popup slightly to let the message appear first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showTutorPopup(TutorTriggerType.keywordDetected);
          }
        });
        break; // Only trigger once per message
      }
    }
  }

  void _handleTutorBooking(TutorSessionType sessionType) {
    // For now, just show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sessionType == TutorSessionType.quickHelp 
          ? 'Quick Help session requested! A tutor will contact you soon.' 
          : 'Deep Session booked! You\'ll receive booking details shortly.'),
        backgroundColor: const Color(0xFF7553F6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildRoseThinkingWidget() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
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
              backgroundImage: AssetImage("assets/avaters/Avatar 2.jpg"),
              radius: 18,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7553F6).withValues(alpha: 0.1),
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
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7553F6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "thinking...",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7553F6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
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
                backgroundImage: AssetImage("assets/avaters/Avatar 2.jpg"),
                radius: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🌟 Mam Rose - AI Tutor",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7553F6),
                      fontFamily: "Poppins",
                    ),
                  ),
                  Consumer<UserService>(
                    builder: (context, userService, child) {
                      return Text(
                        "${widget.topicTitle} • ${userService.gradeDisplay}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF7553F6), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // WhatsApp-style call button for tutor
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showTutorPopup(TutorTriggerType.callButton),
              icon: const Icon(
                Icons.video_call,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Get Tutor Help',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                // Add more options here
              },
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEEF1F8),
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length + (_isRoseThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length && _isRoseThinking) {
                return _buildRoseThinkingWidget();
              }
              return messages[index];
            },
          ),
        ),
        MathInputBar(
          controller: _messageController,
          onSendMessage: _sendMessage,
          onInsertSymbol: _insertMathSymbol,
          onPickImage: _pickImage,
          onTakePhoto: _takePhoto,
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Main chat area
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (_isRoseThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && _isRoseThinking) {
                          return _buildRoseThinkingWidget();
                        }
                        return messages[index];
                      },
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: MathInputBar(
                  controller: _messageController,
                  onSendMessage: _sendMessage,
                  onInsertSymbol: _insertMathSymbol,
                  onPickImage: _pickImage,
                  onTakePhoto: _takePhoto,
                ),
              ),
            ],
          ),
        ),
        // Side panel for topic info and quick actions
        Container(
          width: 300,
          margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: _buildSidePanel(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Main chat area
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Chat header with topic info
                        _buildChatHeader(),
                        // Messages area
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            itemCount: messages.length + (_isRoseThinking ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length && _isRoseThinking) {
                                return _buildRoseThinkingWidget();
                              }
                              return Container(
                                constraints: const BoxConstraints(maxWidth: 700),
                                child: messages[index],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Input area
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: MathInputBar(
                  controller: _messageController,
                  onSendMessage: _sendMessage,
                  onInsertSymbol: _insertMathSymbol,
                  onPickImage: _pickImage,
                  onTakePhoto: _takePhoto,
                ),
              ),
            ],
          ),
        ),
        // Enhanced side panel for desktop
        Container(
          width: 350,
          margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: _buildEnhancedSidePanel(),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
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
              backgroundImage: AssetImage("assets/avaters/Avatar 2.jpg"),
              radius: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🌟 Mam Rose - AI Tutor",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7553F6),
                    fontFamily: "Poppins",
                  ),
                ),
                Consumer<UserService>(
                  builder: (context, userService, child) {
                    return Text(
                      "${widget.topicTitle} • ${userService.gradeDisplay}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Tutor call button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showTutorPopup(TutorTriggerType.callButton),
              icon: const Icon(
                Icons.video_call,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Get Tutor Help',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Current Topic",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.topicTitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7553F6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // Quick actions
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            "Get Tutor Help",
            Icons.school,
            const Color(0xFF7553F6),
            () => _showTutorPopup(TutorTriggerType.callButton),
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            "Take Photo",
            Icons.camera_alt,
            const Color(0xFF4ECDC4),
            _takePhoto,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            "Upload Image",
            Icons.photo_library,
            const Color(0xFFFF6B6B),
            _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSidePanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Session Info",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7553F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Topic",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.topicTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7553F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<UserService>(
                  builder: (context, userService, child) {
                    return Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userService.gradeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chat,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${messages.length} messages",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            "Get Professional Help",
            Icons.video_call,
            const Color(0xFF25D366),
            () => _showTutorPopup(TutorTriggerType.callButton),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            "Take Photo of Problem",
            Icons.camera_alt,
            const Color(0xFF4ECDC4),
            _takePhoto,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            "Upload from Gallery",
            Icons.photo_library,
            const Color(0xFFFF6B6B),
            _pickImage,
          ),
          const Spacer(),
          // Study tips section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Study Tip",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Practice problems step by step. If you get stuck, ask for help by typing keywords like 'help' or 'explain'.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}