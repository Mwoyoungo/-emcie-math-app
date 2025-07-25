import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_animation/services/video_session_service.dart';

class CreateVideoSessionScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateVideoSessionScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CreateVideoSessionScreen> createState() => _CreateVideoSessionScreenState();
}

class _CreateVideoSessionScreenState extends State<CreateVideoSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 60;
  final List<int> _selectedDays = [];
  bool _isLoading = false;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<int> _durationOptions = [30, 45, 60, 90, 120];

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
        title: const Text('Create Video Session'),
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
              _buildSessionDetailsCard(),
              const SizedBox(height: 16),
              _buildScheduleCard(),
              const SizedBox(height: 16),
              _buildRecurringDaysCard(),
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
              Icons.video_call,
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
                  'New Video Session',
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

  Widget _buildSessionDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Session Title',
                hintText: 'e.g., Weekly Math Review',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a session title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of what will be covered...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Time Selection
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFF7553F6)),
              title: const Text('Start Time'),
              subtitle: Text(_formatTime(_selectedTime)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),
            
            const Divider(),
            
            // Duration Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _durationOptions.map((duration) {
                      final isSelected = _durationMinutes == duration;
                      return ChoiceChip(
                        label: Text('${duration}min'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _durationMinutes = duration;
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringDaysCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recurring Days',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the days this session will repeat',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_dayNames.length, (index) {
                final dayIndex = index + 1; // 1=Monday, 7=Sunday
                final isSelected = _selectedDays.contains(dayIndex);
                
                return FilterChip(
                  label: Text(_dayNames[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(dayIndex);
                      } else {
                        _selectedDays.remove(dayIndex);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF7553F6).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF7553F6),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF7553F6) : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }),
            ),
            if (_selectedDays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one day',
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
        onPressed: _isLoading ? null : _createVideoSession,
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
                'Create Video Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _createVideoSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one recurring day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final videoSessionService = context.read<VideoSessionService>();

      // Convert TimeOfDay to DateTime for today
      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final session = await videoSessionService.createVideoSession(
        classId: widget.classId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        durationMinutes: _durationMinutes,
        startTime: startTime,
        recurringDays: List.from(_selectedDays)..sort(),
      );

      if (session != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video session "${session.title}" created successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to create video session');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating video session: $e'),
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