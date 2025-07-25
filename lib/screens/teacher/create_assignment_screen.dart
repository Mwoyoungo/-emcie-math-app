import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/assignment_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateAssignmentScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  int _maxFileSizeMb = 10;
  final List<String> _selectedFileTypes = ['pdf', 'png', 'jpg', 'jpeg'];
  bool _isLoading = false;

  final List<int> _fileSizeOptions = [5, 10, 20, 50];
  final Map<String, String> _fileTypeOptions = {
    'pdf': 'PDF Documents',
    'doc': 'Word Documents',
    'docx': 'Word Documents (DOCX)',
    'png': 'PNG Images',
    'jpg': 'JPEG Images',
    'jpeg': 'JPEG Images',
    'gif': 'GIF Images',
    'txt': 'Text Files',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAssignmentDetailsCard(),
              const SizedBox(height: 16),
              _buildDueDateCard(),
              const SizedBox(height: 16),
              _buildFileRestrictionsCard(),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7553F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7553F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Assignment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7553F6),
                  ),
                ),
                Text(
                  'For: ${widget.className}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
                hintText: 'e.g., Algebra Practice Problems',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an assignment title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Provide instructions and requirements...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter assignment description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Due Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF7553F6)),
              title: const Text('Due Date & Time'),
              subtitle: Text(_formatDueDate(_selectedDueDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDueDate,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Students will be able to submit until ${_formatDueDate(_selectedDueDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRestrictionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Upload Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // File Size Limit
            const Text(
              'Maximum File Size',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _fileSizeOptions.map((size) {
                final isSelected = _maxFileSizeMb == size;
                return ChoiceChip(
                  label: Text('${size}MB'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _maxFileSizeMb = size;
                      });
                    }
                  },
                  selectedColor: const Color(0xFF7553F6).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF7553F6) : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Allowed File Types
            const Text(
              'Allowed File Types',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Students can submit files in these formats',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fileTypeOptions.entries.map((entry) {
                final fileType = entry.key;
                final description = entry.value;
                final isSelected = _selectedFileTypes.contains(fileType);
                
                return FilterChip(
                  label: Text(fileType.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFileTypes.add(fileType);
                      } else {
                        if (_selectedFileTypes.length > 1) {
                          _selectedFileTypes.remove(fileType);
                        }
                      }
                    });
                  },
                  selectedColor: const Color(0xFF7553F6).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF7553F6),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF7553F6) : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  tooltip: description,
                );
              }).toList(),
            ),
            
            if (_selectedFileTypes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one file type',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAssignment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7553F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Create Assignment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7553F6),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF7553F6),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    String dayText;
    if (dueDay == today) {
      dayText = 'Today';
    } else if (dueDay == tomorrow) {
      dayText = 'Tomorrow';
    } else {
      dayText = '${date.day}/${date.month}/${date.year}';
    }

    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dayText at $time';
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFileTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one allowed file type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assignmentService = context.read<AssignmentService>();

      final assignment = await assignmentService.createAssignment(
        classId: widget.classId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        maxFileSizeMb: _maxFileSizeMb,
        allowedFileTypes: List.from(_selectedFileTypes),
      );

      if (assignment != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assignment "${assignment.title}" created successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to create assignment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assignment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}