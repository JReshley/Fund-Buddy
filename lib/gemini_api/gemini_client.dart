import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiClient {
  final String apiKey;
  final String modelName;

  GeminiClient(this.apiKey, {this.modelName = 'gemini-2.0-flash-lite'});

  /// Call the Google Generative Language REST endpoint for generateContent.
  /// Accepts a request body map and returns the raw http.Response.
  Future<http.Response> generateContent(Map<String, dynamic> body) async {
    final Uri url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey');
    print('API URL: $url');
    print('Request Body: ${jsonEncode(body)}');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    print('Response Status: ${resp.statusCode}');
    print('Response Body: ${resp.body}');
    return resp;
  }
}
