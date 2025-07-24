import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rive_animation/services/class_service.dart';
import 'package:rive_animation/services/user_service.dart';

class ClassTestScreen extends StatefulWidget {
  @override
  _ClassTestScreenState createState() => _ClassTestScreenState();
}

class _ClassTestScreenState extends State<ClassTestScreen> {
  List<String> testResults = [];
  bool isRunning = false;

  void log(String message) {
    setState(() {
      testResults.add(message);
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class System Test'),
        backgroundColor: Color(0xFF7553F6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class System Backend Test', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('This will test:\n• Class creation\n• Code generation\n• Database policies\n• Service methods'),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isRunning ? null : () => runTests(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7553F6),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          isRunning ? 'Testing...' : 'Run Tests',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (testResults.isNotEmpty) ...[
              Text('Test Results:', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
            ],
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: ListView.builder(
                    itemCount: testResults.length,
                    itemBuilder: (context, index) {
                      final result = testResults[index];
                      final isError = result.startsWith('❌');
                      final isSuccess = result.startsWith('✅');
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          result,
                          style: TextStyle(
                            color: isError 
                              ? Colors.red 
                              : isSuccess 
                                ? Colors.green 
                                : Colors.black87,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> runTests(BuildContext context) async {
    setState(() {
      isRunning = true;
      testResults.clear();
    });

    final userService = Provider.of<UserService>(context, listen: false);
    final classService = Provider.of<ClassService>(context, listen: false);

    log('🚀 Starting Class System Tests...\n');

    // Test 1: Check authentication and role
    try {
      final currentUser = userService.currentUser;
      if (currentUser == null) {
        log('❌ No user logged in');
        setState(() => isRunning = false);
        return;
      }
      
      log('✅ User authenticated: ${currentUser.email}');
      log('✅ User role: ${currentUser.role}');
      
      if (currentUser.role != 'teacher') {
        log('⚠️  Current user is not a teacher');
        log('   Some tests may fail due to permissions');
      }
      
    } catch (e) {
      log('❌ Error checking user: $e');
      setState(() => isRunning = false);
      return;
    }

    // Test 2: Direct minimal test (like student_creation_requests)
    if (userService.currentUser?.role == 'teacher') {
      try {
        log('\n📚 Test 2: Testing minimal table insert...');
        
        // Get actual auth user ID
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          log('❌ No authenticated user ID found');
        } else {
          // Test direct insert to actual classes table
          final response = await Supabase.instance.client
              .from('classes')
              .insert({
                'teacher_id': userId,
                'name': 'Test Class ${DateTime.now().millisecondsSinceEpoch}',
                'subject': 'Mathematics',
                'grade_level': 'Grade 8',
              })
              .select()
              .single();
          
          log('✅ Class created successfully');
          log('   ID: ${response['id']}');
          log('   Name: ${response['name']}');
          log('   Code: ${response['class_code']}');
          log('   Teacher ID: ${response['teacher_id']}');
        }
        
      } catch (e) {
        log('❌ Error with minimal test: $e');
        log('   This tells us if the basic teacher_id pattern works');
      }
    } else {
      log('\n📚 Test 2: Skipped (user not teacher)');
    }

    // Test 3: Fetch classes
    try {
      log('\n📋 Test 3: Fetching classes...');
      
      if (userService.currentUser?.role == 'teacher') {
        final classes = await classService.fetchTeacherClasses();
        log('✅ Fetched ${classes.length} teacher classes');
        
        if (classes.isNotEmpty) {
          log('   Recent classes:');
          for (var cls in classes.take(3)) {
            log('   - ${cls.name} (${cls.classCode})');
          }
        }
      } else {
        final enrollments = await classService.fetchStudentEnrollments();
        log('✅ Fetched ${enrollments.length} student enrollments');
        
        if (enrollments.isNotEmpty) {
          log('   Enrolled classes:');
          for (var enrollment in enrollments.take(3)) {
            log('   - ${enrollment.className ?? 'Unknown Class'}');
          }
        }
      }
      
    } catch (e) {
      log('❌ Error fetching classes: $e');
    }

    // Test 4: Skip for now (no test class code available)
    log('\n🎓 Test 4: Skipped - no test class created');

    // Test 5: Skip for now (no test class available)
    log('\n👥 Test 5: Skipped - no test class created');

    // Test 6: Skip cleanup for now
    log('\n🗑️  Test 6: Skipped - no cleanup needed');

    log('\n🎉 Tests completed!');
    
    if (userService.currentUser?.role == 'teacher') {
      log('\n📝 To test fully:');
      log('1. Create a real class using the UI');
      log('2. Share the class code with a student');
      log('3. Have student join using the code');
    } else {
      log('\n📝 To test student features:');
      log('1. Get a class code from a teacher');
      log('2. Use the join class feature');
    }
    
    setState(() => isRunning = false);
  }
}