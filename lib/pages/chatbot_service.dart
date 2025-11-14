// lib/services/chatbot_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ChatbotService {
  // Set this to the correct URL for your environment:
  // Android emulator: use 'http://10.0.2.2:8000'
  // iOS simulator: use 'http://localhost:8000'
  // Physical device: use ngrok https URL e.g. 'https://abcd1234.ngrok.io'
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Send text message to FastAPI chatbot
  // Expects backend /chat to accept JSON { "user_id": "...", "message": "..." }
  // and return { "response": "..." }
  static Future<String> sendMessage(String message, {String userId = 'me'}) async {
    final uri = Uri.parse('$baseUrl/chat');
    final body = jsonEncode({'user_id': userId, 'message': message});

    final response = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // backend returns {"response": "..."}
      if (data is Map && data.containsKey('response')) {
        return data['response'].toString();
      } else {
        throw Exception('Unexpected response format: ${response.body}');
      }
    } else {
      throw Exception('Failed to get chatbot response: ${response.statusCode} ${response.body}');
    }
  }

  // Upload Excel/DOCX/text file to backend and return parsed result message
  // Expects backend /upload_file to accept form file field "file" and return {"message": "...", "result": {...}}
  static Future<Map<String, dynamic>> uploadFile(File file) async {
    final uri = Uri.parse('$baseUrl/upload_file');
    final request = http.MultipartRequest('POST', uri);

    // Attach file (content type left as default octet-stream)
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // returns {"message": "...", "result": ...}
      return data;
    } else {
      throw Exception('File upload failed: ${response.statusCode} ${response.body}');
    }
  }
}
