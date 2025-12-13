import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Chapter PDF Service Integration Tests', () {
    const String baseUrl = 'http://localhost:5001';
    
    testWidgets('Backend API availability test', (tester) async {
      // Test server status
      final statusResponse = await http.get(Uri.parse('$baseUrl/status'));
      expect(statusResponse.statusCode, 200);
      
      final statusData = json.decode(statusResponse.body);
      expect(statusData['firebase_initialized'], true);
      expect(statusData['firestore_available'], true);
    });
    
    testWidgets('Available chapters API test', (tester) async {
      // Test getting available chapters for Class 9
      final response = await http.get(
        Uri.parse('$baseUrl/api/chapters/available/9'),
      );
      
      expect(response.statusCode, 200);
      
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['chapters'], isA<List>());
      expect(data['class_level'], 9);
      
      // Check if chapters have required fields
      final chapters = data['chapters'] as List;
      if (chapters.isNotEmpty) {
        final firstChapter = chapters.first;
        expect(firstChapter['chapter_id'], isNotNull);
        expect(firstChapter['displayTitle'], isNotNull);
        expect(firstChapter['displaySubtitle'], isNotNull);
        expect(firstChapter['is_available'], isA<bool>());
      }
    });
    
    testWidgets('Chapter download info API test', (tester) async {
      // Test getting download info for real_numbers chapter
      final response = await http.get(
        Uri.parse('$baseUrl/api/chapter/9/real_numbers/download_info'),
      );
      
      expect(response.statusCode, 200);
      
      final data = json.decode(response.body);
      expect(data['success'], true);
      
      if (data['download_ready'] == true) {
        expect(data['download_url'], isNotNull);
        expect(data['chapter_info'], isNotNull);
        expect(data['chapter_info']['chapter_id'], 'real_numbers');
        expect(data['chapter_info']['class_level'], 9);
        expect(data['file_size'], isA<int>());
      }
    });
    
    testWidgets('Firebase download URL accessibility test', (tester) async {
      // First get the download info
      final infoResponse = await http.get(
        Uri.parse('$baseUrl/api/chapter/9/real_numbers/download_info'),
      );
      
      if (infoResponse.statusCode == 200) {
        final data = json.decode(infoResponse.body);
        
        if (data['download_ready'] == true && data['download_url'] != null) {
          // Test if the Firebase URL is accessible
          final downloadUrl = data['download_url'] as String;
          final urlResponse = await http.head(Uri.parse(downloadUrl));
          
          // Should be accessible (200 OK)
          expect(urlResponse.statusCode, 200);
          expect(urlResponse.headers['content-type'], contains('pdf'));
        }
      }
    });
  });
}
