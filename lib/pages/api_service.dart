// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService(this.baseUrl, {this.timeout = const Duration(seconds: 30)});

  // Send chat message
  Future<String> sendMessage(String message, {String userId = 'me'}) async {
    final url = Uri.parse('$baseUrl/chat');
    final body = jsonEncode({'user_id': userId, 'message': message});

    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('response')) {
          return data['response'].toString();
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }
      } else {
        throw Exception('Chat failed: ${response.statusCode} ${response.body}');
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error: $e');
    } on FormatException {
      throw Exception('Bad response format from server');
    }
  }

  // Upload file (Excel / CSV)
  // Note: this expects your backend upload endpoint to be /upload (adjust if needed)
  Future<Map<String, dynamic>> uploadFile(File file) async {
    final uri = Uri.parse('$baseUrl/upload'); // change to /upload_file if backend uses that
    final request = http.MultipartRequest('POST', uri);

    try {
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();

      // better filename extraction
      final filename = p.basename(file.path);
      final ext = p.extension(filename).toLowerCase();

      // detect mime type for excel/csv if possible
      String mimeType = 'application/octet-stream';
      String mimeMain = 'application';
      String mimeSub = 'octet-stream';

      if (ext == '.xlsx') {
        mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        mimeMain = 'application';
        mimeSub = 'vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (ext == '.xls') {
        mimeType = 'application/vnd.ms-excel';
        mimeMain = 'application';
        mimeSub = 'vnd.ms-excel';
      } else if (ext == '.csv') {
        mimeType = 'text/csv';
        mimeMain = 'text';
        mimeSub = 'csv';
      }

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: filename,
        contentType: MediaType(mimeMain, mimeSub),
      );

      request.files.add(multipartFile);
      // Add headers if needed (e.g., auth)
      request.headers.addAll({'Accept': 'application/json'});

      final streamedResponse =
      await request.send().timeout(timeout + Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'message': responseBody};
        }
      } else {
        throw Exception(
            'File upload failed: ${streamedResponse.statusCode} $responseBody');
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } on FormatException {
      throw Exception('Bad response format from server');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
}
