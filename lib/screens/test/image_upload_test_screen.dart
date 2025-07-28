import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';

class ImageUploadTestScreen extends StatefulWidget {
  const ImageUploadTestScreen({super.key});

  @override
  State<ImageUploadTestScreen> createState() => _ImageUploadTestScreenState();
}

class _ImageUploadTestScreenState extends State<ImageUploadTestScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String _debugLog = '';
  bool _isLoading = false;
  String? _selectedImagePath;
  String? _apiResponse;
  String? _errorMessage;

  void _addToLog(String message) {
    setState(() {
      _debugLog += '${DateTime.now().toIso8601String()}: $message\n';
    });
    print(message);
  }

  Future<void> _testImageUpload() async {
    setState(() {
      _isLoading = true;
      _debugLog = '';
      _apiResponse = null;
      _errorMessage = null;
    });

    _addToLog('🚀 Starting image upload test...');

    try {
      // Pick image
      _addToLog('📱 Opening image picker...');
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        _addToLog('❌ No image selected');
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _selectedImagePath = image.path;
      });

      _addToLog('✅ Image selected: ${image.name}');
      _addToLog('📁 Image path: ${image.path}');

      // Convert to ImageUpload
      _addToLog('🔄 Converting image to base64...');
      final imageUpload = await ImageUpload.fromXFile(image, image.name);
      _addToLog('✅ Image converted to base64');
      _addToLog('📊 Base64 length: ${imageUpload.data.length}');
      _addToLog('📋 MIME type: ${imageUpload.mime}');
      _addToLog('📋 File name: ${imageUpload.name}');

      // Test API call
      _addToLog('🌐 Calling Flowise API...');
      final response = await AIService.getAssessmentResponse(
        "Here is my answer in this image.",
        chatId: 'test_session_${DateTime.now().millisecondsSinceEpoch}',
        images: [imageUpload],
      );

      _addToLog('✅ API call completed');
      _addToLog('📝 Response text: ${response.text}');
      _addToLog('🆔 Chat ID: ${response.chatId}');
      _addToLog('🆔 Session ID: ${response.sessionId}');

      setState(() {
        _apiResponse = response.text;
      });

    } catch (e) {
      _addToLog('❌ Error occurred: $e');
      _addToLog('❌ Error type: ${e.runtimeType}');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Test'),
        backgroundColor: const Color(0xFF7553F6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Image Upload to Flowise AI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testImageUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7553F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Testing Image Upload...'),
                        ],
                      )
                    : const Text(
                        'Test Image Upload',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Results Section
            if (_selectedImagePath != null) ...[
              const Text(
                'Selected Image:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Path: $_selectedImagePath'),
              const SizedBox(height: 16),
            ],
            
            if (_apiResponse != null) ...[
              const Text(
                'API Response:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_apiResponse!),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_errorMessage != null) ...[
              const Text(
                'Error:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!),
              ),
              const SizedBox(height: 16),
            ],
            
            // Debug Log
            const Text(
              'Debug Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugLog.isEmpty ? 'No debug information yet. Click "Test Image Upload" to start.' : _debugLog,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}