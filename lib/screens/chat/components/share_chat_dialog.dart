import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/chat_sharing_service.dart';
import 'package:rive_animation/services/chat_session_service.dart';

class ShareChatDialog extends StatefulWidget {
  final ChatSession chatSession;

  const ShareChatDialog({
    super.key,
    required this.chatSession,
  });

  @override
  State<ShareChatDialog> createState() => _ShareChatDialogState();
}

class _ShareChatDialogState extends State<ShareChatDialog> {
  // Note: Message functionality removed to match simplified database schema
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedClass;
  bool _isLoading = false;
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await context.read<ChatSharingService>().getStudentClasses();
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
        if (classes.isNotEmpty) {
          _selectedClass = classes.first;
        }
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.share, color: Color(0xFF7553F6)),
          const SizedBox(width: 8),
          const Text('Share Chat with Teacher'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your AI conversation about "${widget.chatSession.topicTitle}" with your teacher.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            
            // Class Selection
            if (_isLoadingClasses)
              const Center(child: CircularProgressIndicator())
            else if (_classes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You need to join a class first to share chats with teachers.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const Text(
                'Select Class:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _selectedClass,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() => _selectedClass = value);
                    },
                    items: _classes.map((classData) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: classData,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              classData['class_name'] ?? 'Unknown Class',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Teacher: ${classData['teacher_name'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Chat Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Summary:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Topic: ${widget.chatSession.topicTitle}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• Messages: ${widget.chatSession.messages.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• Started: ${_formatDate(widget.chatSession.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _classes.isEmpty || _selectedClass == null) 
              ? null 
              : _shareChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7553F6),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Share'),
        ),
      ],
    );
  }

  Future<void> _shareChat() async {
    if (_selectedClass == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await context.read<ChatSharingService>().shareChat(
        classId: _selectedClass!['class_id'],
        chatSession: widget.chatSession,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chat shared with ${_selectedClass!['teacher_name']} successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to share chat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing chat: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}