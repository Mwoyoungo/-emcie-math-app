import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/class_service.dart';
import 'package:rive_animation/services/user_service.dart';
import 'package:rive_animation/screens/teacher/teacher_class_detail_screen.dart';

class TeacherClassesScreen extends StatefulWidget {
  @override
  _TeacherClassesScreenState createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassService>().fetchTeacherClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            // Classes List
            Expanded(
              child: Consumer<ClassService>(
                builder: (context, classService, child) {
                  if (classService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final classes = classService.teacherClasses;
                  
                  if (classes.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildClassesList(classes);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context),
        backgroundColor: const Color(0xFF7553F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Class', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Classes',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<UserService>(
            builder: (context, userService, child) {
              return Text(
                'Welcome back, ${userService.currentUser?.fullName ?? 'Teacher'}!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Classes Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first class to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateClassDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7553F6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Your First Class',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList(List<SchoolClass> classes) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final schoolClass = classes[index];
        return _buildClassCard(schoolClass);
      },
    );
  }

  Widget _buildClassCard(SchoolClass schoolClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewClassDetails(schoolClass),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schoolClass.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (schoolClass.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            schoolClass.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleClassAction(value, schoolClass),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Class Info Row
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.subject,
                    label: schoolClass.subject,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (schoolClass.gradeLevel != null)
                    _buildInfoChip(
                      icon: Icons.grade,
                      label: schoolClass.gradeLevel!,
                      color: Colors.green,
                    ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${schoolClass.enrolledCount ?? 0} students',
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Class Code Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7553F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF7553F6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.key,
                      size: 16,
                      color: Color(0xFF7553F6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Class Code: ${schoolClass.classCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7553F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyClassCode(schoolClass.classCode),
                      child: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Color(0xFF7553F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  void _viewClassDetails(SchoolClass schoolClass) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherClassDetailScreen(schoolClass: schoolClass),
      ),
    );
  }

  void _handleClassAction(String action, SchoolClass schoolClass) {
    switch (action) {
      case 'edit':
        _showEditClassDialog(schoolClass);
        break;
      case 'delete':
        _showDeleteConfirmation(schoolClass);
        break;
    }
  }

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateClassDialog(),
    );
  }

  void _showEditClassDialog(SchoolClass schoolClass) {
    showDialog(
      context: context,
      builder: (context) => CreateClassDialog(editClass: schoolClass),
    );
  }

  void _showDeleteConfirmation(SchoolClass schoolClass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "${schoolClass.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ClassService>().deleteClass(schoolClass.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class deleted successfully'),
                    backgroundColor: Colors.green,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class CreateClassDialog extends StatefulWidget {
  final SchoolClass? editClass;

  const CreateClassDialog({Key? key, this.editClass}) : super(key: key);

  @override
  _CreateClassDialogState createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editClass != null) {
      _nameController.text = widget.editClass!.name;
      _descriptionController.text = widget.editClass!.description ?? '';
      _subjectController.text = widget.editClass!.subject;
      _gradeLevelController.text = widget.editClass!.gradeLevel ?? '';
    } else {
      _subjectController.text = 'Mathematics';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editClass != null ? 'Edit Class' : 'Create New Class'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name *',
                  hintText: 'e.g., Algebra 1 - Period 3',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a class name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the class',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g., Mathematics, Physics',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeLevelController,
                decoration: const InputDecoration(
                  labelText: 'Grade Level',
                  hintText: 'e.g., Grade 8, Year 10',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveClass,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7553F6),
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
              : Text(
                  widget.editClass != null ? 'Update' : 'Create',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final classService = context.read<ClassService>();

      if (widget.editClass != null) {
        // Update existing class
        await classService.updateClass(
          widget.editClass!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          subject: _subjectController.text.trim(),
          gradeLevel: _gradeLevelController.text.trim().isEmpty
              ? null
              : _gradeLevelController.text.trim(),
        );
      } else {
        // Create new class
        await classService.createClass(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          subject: _subjectController.text.trim(),
          gradeLevel: _gradeLevelController.text.trim().isEmpty
              ? null
              : _gradeLevelController.text.trim(),
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editClass != null
                ? 'Class updated successfully'
                : 'Class created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _gradeLevelController.dispose();
    super.dispose();
  }
}