import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/chat_sharing_service.dart';
import 'package:rive_animation/screens/teacher/shared_chat_detail_screen.dart';
import '../../widgets/next_video_session_widget.dart';

class TeacherSharedChatsScreen extends StatefulWidget {
  const TeacherSharedChatsScreen({super.key});

  @override
  State<TeacherSharedChatsScreen> createState() =>
      _TeacherSharedChatsScreenState();
}

class _TeacherSharedChatsScreenState extends State<TeacherSharedChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatSharingService>().fetchTeacherSharedChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Shared Chats'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ChatSharingService>(
        builder: (context, chatSharingService, child) {
          if (chatSharingService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sharedChats = chatSharingService.teacherSharedChats;

          if (sharedChats.isEmpty) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Next Video Session Widget for Teachers
                  const NextVideoSessionWidget(),
                  
                  // Empty State
                  _buildEmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatSharingService.fetchTeacherSharedChats(),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Next Video Session Widget for Teachers
                  const NextVideoSessionWidget(),
                  
                  // Shared Chats List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: sharedChats.length,
                    itemBuilder: (context, index) {
                      final sharedChat = sharedChats[index];
                      return _buildSharedChatCard(sharedChat);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Shared Chats Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Students will be able to share their AI conversations with you here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedChatCard(SharedChat sharedChat) {
    final messageCount = sharedChat.chatSession.messages.length;
    final lastMessageTime = sharedChat.chatSession.messages.isNotEmpty
        ? sharedChat.chatSession.messages.last.timestamp
        : sharedChat.sharedAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewSharedChat(sharedChat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Student Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7553F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'S', // Student
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7553F6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Student Chat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Removed isRead functionality for simplified schema
                          ],
                        ),
                        Text(
                          'Class Discussion',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time
                  Text(
                    _formatTime(sharedChat.sharedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Topic and Message Count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.topic, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        sharedChat.topicTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Stats Row
              Row(
                children: [
                  _buildStatChip(
                      '$messageCount messages', Icons.chat, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    'Last: ${_formatTime(lastMessageTime)}',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ],
              ),

              // Message functionality removed for simplified schema
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  void _viewSharedChat(SharedChat sharedChat) {
    // Navigate to detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedChatDetailScreen(sharedChat: sharedChat),
      ),
    );
  }
}
