import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/class_service.dart';
import 'package:rive_animation/services/chat_sharing_service.dart';
import 'package:rive_animation/screens/teacher/teacher_shared_chats_screen.dart';
import 'package:rive_animation/screens/teacher/create_assignment_screen.dart';
import 'package:rive_animation/screens/teacher/create_video_session_screen.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final SchoolClass schoolClass;

  const TeacherClassDetailScreen({
    super.key,
    required this.schoolClass,
  });

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClassEnrollment> _enrollments = [];
  bool _isLoadingEnrollments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEnrollments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoadingEnrollments = true);
    try {
      final classService = context.read<ClassService>();
      final enrollments = await classService.getClassStudents(widget.schoolClass.id);
      setState(() {
        _enrollments = enrollments;
        _isLoadingEnrollments = false;
      });
    } catch (e) {
      setState(() => _isLoadingEnrollments = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schoolClass.name),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _shareClassCode(),
            icon: const Icon(Icons.share),
          ),
          Consumer<ChatSharingService>(
            builder: (context, chatSharingService, child) {
              final unreadCount = chatSharingService.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => _viewSharedChats(),
                    icon: const Icon(Icons.chat),
                    tooltip: 'Shared Chats',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Class'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20),
                    SizedBox(width: 8),
                    Text('Archive Class'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStudentsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassInfoCard(),
          const SizedBox(height: 20),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7553F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.class_,
                    color: Color(0xFF7553F6),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.schoolClass.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.schoolClass.description != null)
                        Text(
                          widget.schoolClass.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.subject, 'Subject', widget.schoolClass.subject),
            if (widget.schoolClass.gradeLevel != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.grade, 'Grade Level', widget.schoolClass.gradeLevel!),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(Icons.people, 'Enrolled Students', '${widget.schoolClass.enrolledCount ?? 0}'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildClassCodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7553F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7553F6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class Code',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.schoolClass.classCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7553F6),
                    letterSpacing: 2,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _copyClassCode(widget.schoolClass.classCode),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7553F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code with students to let them join your class',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.assignment,
                    label: 'Create\nAssignment',
                    color: Colors.blue,
                    onTap: () => _createAssignment(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.video_call,
                    label: 'Schedule\nVideo Session',
                    color: Colors.green,
                    onTap: () => _createVideoSession(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.settings,
                    label: 'Class\nSettings',
                    color: Colors.orange,
                    onTap: () => _tabController.animateTo(2), // Go to Settings tab
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Share Class\nCode',
                    color: Colors.purple,
                    onTap: () => _shareClassCode(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStudentsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Students (${_enrollments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _shareClassCode,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Invite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7553F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingEnrollments
              ? const Center(child: CircularProgressIndicator())
              : _enrollments.isEmpty
                  ? _buildEmptyStudentsState()
                  : _buildStudentsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Students Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your class code to invite students',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _shareClassCode,
            icon: const Icon(Icons.share),
            label: const Text('Share Class Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7553F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = _enrollments[index];
        return _buildStudentCard(enrollment);
      },
    );
  }

  Widget _buildStudentCard(ClassEnrollment enrollment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7553F6).withValues(alpha: 0.1),
          child: Text(
            (enrollment.studentName ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF7553F6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          enrollment.studentName ?? 'Unknown Student',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Joined ${_formatEnrollmentDate(enrollment.enrolledAt)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleStudentAction(value, enrollment),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_progress',
              child: Row(
                children: [
                  Icon(Icons.analytics, size: 20),
                  SizedBox(width: 8),
                  Text('View Progress'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.remove_circle, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove Student', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSettingsSection('Class Information', [
          _buildSettingsTile(
            icon: Icons.edit,
            title: 'Edit Class Details',
            subtitle: 'Change name, description, subject',
            onTap: () => _editClass(),
          ),
          _buildSettingsTile(
            icon: Icons.refresh,
            title: 'Regenerate Class Code',
            subtitle: 'Create a new class code',
            onTap: () => _regenerateClassCode(),
          ),
        ]),
        const SizedBox(height: 20),
        _buildSettingsSection('Class Management', [
          _buildSettingsTile(
            icon: Icons.archive,
            title: 'Archive Class',
            subtitle: 'Hide class from active list',
            onTap: () => _archiveClass(),
          ),
          _buildSettingsTile(
            icon: Icons.delete,
            title: 'Delete Class',
            subtitle: 'Permanently delete this class',
            onTap: () => _deleteClass(),
            isDestructive: true,
          ),
        ]),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF7553F6),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right),
    );
  }

  void _copyClassCode(String classCode) {
    Clipboard.setData(ClipboardData(text: classCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Class code $classCode copied to clipboard'),
        backgroundColor: const Color(0xFF7553F6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareClassCode() {
    _copyClassCode(widget.schoolClass.classCode);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share this code: copied to clipboard'),
        backgroundColor: Color(0xFF7553F6),
      ),
    );
  }

  void _viewSharedChats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherSharedChatsScreen(),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editClass();
        break;
      case 'archive':
        _archiveClass();
        break;
    }
  }

  void _handleStudentAction(String action, ClassEnrollment enrollment) {
    switch (action) {
      case 'view_progress':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${enrollment.studentName}\'s progress...')),
        );
        break;
      case 'remove':
        _removeStudent(enrollment);
        break;
    }
  }

  void _editClass() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit class functionality coming soon...')),
    );
  }

  void _regenerateClassCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Class Code'),
        content: const Text(
          'This will create a new class code. Students will need the new code to join. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New class code generated'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7553F6)),
            child: const Text('Generate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _archiveClass() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Class'),
        content: const Text('This will hide the class from your active list. You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Class archived successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteClass() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to permanently delete "${widget.schoolClass.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ClassService>().deleteClass(widget.schoolClass.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting class: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removeStudent(ClassEnrollment enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove ${enrollment.studentName} from this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _enrollments.remove(enrollment);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${enrollment.studentName} removed from class'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatEnrollmentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  void _createAssignment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAssignmentScreen(
          classId: widget.schoolClass.id,
          className: widget.schoolClass.name,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Assignment was created successfully, refresh the class data
        _loadEnrollments();
      }
    });
  }

  void _createVideoSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVideoSessionScreen(
          classId: widget.schoolClass.id,
          className: widget.schoolClass.name,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Video session was created successfully, refresh the class data
        _loadEnrollments();
      }
    });
  }
}