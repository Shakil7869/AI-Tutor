import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../shared/services/rag_service.dart';

class PDFUploadScreen extends ConsumerStatefulWidget {
  const PDFUploadScreen({super.key});

  @override
  ConsumerState<PDFUploadScreen> createState() => _PDFUploadScreenState();
}

class _PDFUploadScreenState extends ConsumerState<PDFUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterController = TextEditingController();
  
  String? _selectedClass;
  String? _selectedSubject;
  File? _selectedFile;
  bool _isUploading = false;
  
  final List<String> _classes = ['9', '10', '11', '12'];
  final List<String> _subjects = ['Physics', 'Chemistry', 'Biology', 'Mathematics'];

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      print('📁 Starting file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      print('📁 FilePicker result: $result');
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        print('📁 Selected file path: $filePath');
        print('📁 File name: ${result.files.single.name}');
        print('📁 File size: ${result.files.single.size}');
        
        setState(() {
          _selectedFile = File(filePath);
        });
        
        print('📁 File selection successful: ${_selectedFile?.path}');
      } else {
        print('📁 No file selected or path is null');
      }
    } catch (e) {
      print('❌ Error in file picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadTextbook() async {
    print('🚀 Starting upload process...');
    print('🚀 Form valid: ${_formKey.currentState?.validate()}');
    print('🚀 File selected: ${_selectedFile != null}');
    print('🚀 Selected class: $_selectedClass');
    print('🚀 Selected subject: $_selectedSubject');
    print('🚀 Chapter name: ${_chapterController.text}');
    
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      print('❌ Validation failed or no file selected');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('🔧 Getting RAG service...');
      final ragService = ref.read(ragServiceProvider);
      
      // Check which URL the service is using
      final isUsingLocal = ragService.toString().contains('127.0.0.1') || 
                          ragService.toString().contains('localhost');
      print('🌐 Service endpoint check:');
      print('   Is using local: $isUsingLocal');
      print('   Service details: $ragService');
      
      print('📤 Starting upload with:');
      print('   File: ${_selectedFile!.path}');
      print('   Class: $_selectedClass');
      print('   Subject: $_selectedSubject');
      print('   Chapter: ${_chapterController.text.trim().isEmpty ? 'auto-detect' : _chapterController.text.trim()}');
      
      final response = await ragService.uploadTextbook(
        file: _selectedFile!,
        classLevel: _selectedClass!,
        subject: _selectedSubject!,
        chapterName: _chapterController.text.trim().isEmpty 
          ? null 
          : _chapterController.text.trim(),
      );

      print('✅ Upload successful: $response');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully processed ${response.chunksCount} chunks from '
              '${response.subject} Class ${response.classLevel}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _selectedClass = null;
          _selectedSubject = null;
          _selectedFile = null;
          _chapterController.clear();
        });
        
        print('🔄 Form reset complete');
      }
    } catch (e, stackTrace) {
      print('❌ Upload error: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        print('🏁 Upload process finished');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Textbook PDF'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NCTB Textbook Upload',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Upload and process NCTB textbooks for AI tutoring',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // File selection
              Text(
                'Select PDF File',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFile != null 
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.shade50,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: _selectedFile != null 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null 
                          ? 'File selected: ${_selectedFile!.path.split('/').last}'
                          : 'Tap to select PDF file',
                        style: TextStyle(
                          color: _selectedFile != null 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.shade600,
                          fontWeight: _selectedFile != null 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Class selection
              Text(
                'Class Level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Select class level',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a class level';
                  }
                  return null;
                },
                items: _classes.map((classLevel) {
                  return DropdownMenuItem(
                    value: classLevel,
                    child: Text('Class $classLevel'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Subject selection
              Text(
                'Subject',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Select subject',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a subject';
                  }
                  return null;
                },
                items: _subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Chapter name (optional)
              Text(
                'Chapter Name (Optional)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _chapterController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Leave empty for auto-detection',
                  helperText: 'AI will automatically detect chapter names if left empty',
                ),
              ),
              const SizedBox(height: 32),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadTextbook,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
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
                          Text('Processing...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload),
                          SizedBox(width: 8),
                          Text('Upload and Process'),
                        ],
                      ),
                ),
              ),
              
              if (_isUploading) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Steps:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Extracting text from PDF'),
                      const Text('2. Chunking content intelligently'),
                      const Text('3. Generating embeddings'),
                      const Text('4. Storing in vector database'),
                      const Text('5. Saving metadata to Firestore'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
