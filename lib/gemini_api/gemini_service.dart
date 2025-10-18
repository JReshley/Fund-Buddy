import 'dart:convert';
import 'dart:typed_data';
import 'gemini_client.dart';

class GeminiService {
  final GeminiClient _client;

  GeminiService(String apiKey) : _client = GeminiClient(apiKey);

  /// Scan receipt image and return structured JSON
  Future<Map<String, dynamic>> scanReceipt(Uint8List imageBytes) async {
    // Build a minimal JSON request body for the REST generateContent API.
    final String prompt = '''
Extract the following details from this receipt image.

IMPORTANT: Format the date as YYYY-MM-DD. If the year is abbreviated (like "20" or "24"), convert it to full year (2020 or 2024). If the year is ambiguous or missing, use the current year (2024).

If a detail is missing, use:
- "N/A" for strings
- 0.00 for numbers

For description, describe the items as a whole in 8 words maximum, if they are different, describe them in categories.

Return the result strictly following the schema with fields: sellerName, receiptControlNum, totalAmount, date (in YYYY-MM-DD format), description.
''';

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Encode(imageBytes)
              }
            },
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.0,
        "responseMimeType": "application/json"
      }
    };

    final resp = await _client.generateContent(requestBody);

    // Debug logging
    print('=== GEMINI API RESPONSE ===');
    print('Status Code: ${resp.statusCode}');
    print('Response Body: ${resp.body}');
    print('==========================');

    if (resp.statusCode != 200) {
      print('ERROR: Non-200 response from Gemini API');
      print('Full error response: ${resp.body}');
      // Try to parse error message
      try {
        final errorBody = jsonDecode(resp.body);
        final errorMessage = errorBody['error']?['message'] ?? resp.body;
        return {
          "sellerName": "API Error ${resp.statusCode}",
          "receiptControlNum": "Check console",
          "totalAmount": 0.00,
          "date": "N/A",
          "description": errorMessage.toString().substring(0, errorMessage.toString().length > 50 ? 50 : errorMessage.toString().length),
        };
      } catch (_) {
        return {
          "sellerName": "API Error ${resp.statusCode}",
          "receiptControlNum": "Check console",
          "totalAmount": 0.00,
          "date": "N/A",
          "description": resp.body.length > 50 ? resp.body.substring(0, 50) : resp.body,
        };
      }
    }

    try {
      // Parse standard REST response body and look for text output.
      final Map<String, dynamic> body = jsonDecode(resp.body);

      // Common location: candidates[0].content.parts[0].text
      try {
        if (body.containsKey('candidates')) {
          final cand = body['candidates'];
          print('Found candidates: ${cand.length}');
          if (cand is List && cand.isNotEmpty) {
            final first = cand[0];
            print('First candidate: $first');
            if (first is Map && first.containsKey('content')) {
              final content = first['content'];
              print('Content: $content');
              if (content is Map && content.containsKey('parts')) {
                final parts = content['parts'];
                print('Parts: $parts');
                if (parts is List && parts.isNotEmpty) {
                  final p0 = parts[0];
                  print('First part: $p0');
                  if (p0 is Map && p0.containsKey('text')) {
                    final textContent = p0['text'] as String;
                    print('Text content: $textContent');
                    try {
                      final parsed = jsonDecode(textContent);
                      print('Successfully parsed JSON: $parsed');
                      
                      // Handle if the response is wrapped in an array
                      if (parsed is List && parsed.isNotEmpty) {
                        print('Response is a list, taking first element');
                        return parsed[0] as Map<String, dynamic>;
                      } else if (parsed is Map<String, dynamic>) {
                        return parsed;
                      } else {
                        print('Unexpected parsed type: ${parsed.runtimeType}');
                      }
                    } catch (jsonErr) {
                      print('JSON parse error: $jsonErr');
                      print('Raw text was: $textContent');
                    }
                  }
                }
              }
            }
            // fallback: sometimes candidates[0]['text']
            if (cand[0] is Map && cand[0].containsKey('text')) {
              final textContent = cand[0]['text'] as String;
              print('Fallback text: $textContent');
              try {
                final parsed = jsonDecode(textContent);
                // Handle if the response is wrapped in an array
                if (parsed is List && parsed.isNotEmpty) {
                  print('Fallback: Response is a list, taking first element');
                  return parsed[0] as Map<String, dynamic>;
                } else if (parsed is Map<String, dynamic>) {
                  return parsed;
                }
              } catch (jsonErr) {
                print('Fallback JSON parse error: $jsonErr');
              }
            }
          }
        } else {
          print('No candidates key in response body');
        }
      } catch (e) {
        print('Error parsing candidates: $e');
      }

      // Another shape: output[0].content[0].text or top-level 'text'
      try {
        if (body.containsKey('output')) {
          final out = body['output'];
          if (out is List && out.isNotEmpty) {
            final first = out[0];
            if (first is Map && first.containsKey('content')) {
              final content = first['content'];
              if (content is List && content.isNotEmpty) {
                final c0 = content[0];
                if (c0 is Map && c0.containsKey('text')) {
                  return jsonDecode(c0['text'] as String) as Map<String, dynamic>;
                }
              }
            }
          }
        }
      } catch (_) {}

      if (body.containsKey('text')) {
        try {
          return jsonDecode(body['text'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }

      // If nothing parsed, return placeholders
      return {
        "sellerName": "N/A",
        "receiptControlNum": "N/A",
        "totalAmount": 0.00,
        "date": "N/A",
        "description": "N/A",
      };
    } catch (_) {
      return {
        "sellerName": "N/A",
        "receiptControlNum": "N/A",
        "totalAmount": 0.00,
        "date": "N/A",
        "description": "N/A",
      };
    }
  }

  /// Revise disclosure text
  Future<String> reviseDisclosure(String initialDisclosure) async {
    final prompt = '''
Revise the disclosure text. The final result must include and clearly label:

- Recipient: Who received or benefited?
- Purpose: What was the intended purpose?
- Particulars: Details of items or services
- Mode: Mode of transaction (cash, bank, online, etc.)

If any are missing, return this exact format:
ALERT: Insufficient Information. Please provide the following details to complete the disclosure: [MISSING DETAIL 1], [MISSING DETAIL 2], ...
''';

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {"text": "$prompt\n\nInitial disclosure: $initialDisclosure"}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.3
      }
    };

    try {
      final resp = await _client.generateContent(requestBody);
      final Map<String, dynamic> body = jsonDecode(resp.body);

      String textOutput = '';
      try {
        if (body.containsKey('candidates')) {
          final cand = body['candidates'];
          if (cand is List && cand.isNotEmpty) {
            final first = cand[0];
            if (first is Map && first.containsKey('content')) {
              final content = first['content'];
              if (content is Map && content.containsKey('parts')) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final p0 = parts[0];
                  if (p0 is Map && p0.containsKey('text')) textOutput = p0['text'] as String;
                }
              }
            }
            if (textOutput.isEmpty && cand[0] is Map && cand[0].containsKey('text')) {
              textOutput = cand[0]['text'] as String;
            }
          }
        }
      } catch (_) {}

      if (textOutput.isEmpty && body.containsKey('output')) {
        try {
          final out = body['output'];
          if (out is List && out.isNotEmpty) {
            final first = out[0];
            if (first is Map && first.containsKey('content')) {
              final content = first['content'];
              if (content is List && content.isNotEmpty) {
                final c0 = content[0];
                if (c0 is Map && c0.containsKey('text')) textOutput = c0['text'] as String;
              }
            }
          }
        } catch (_) {}
      }

      if (textOutput.isEmpty && body.containsKey('text')) {
        textOutput = body['text'].toString();
      }

      if (textOutput.isEmpty) {
        return _insufficientAlert(['Recipient', 'Purpose', 'Particulars', 'Mode']);
      }

      // Validate labels
      final missing = <String>[];
      if (!_hasLabel(textOutput, 'Recipient')) missing.add('Recipient');
      if (!_hasLabel(textOutput, 'Purpose')) missing.add('Purpose');
      if (!_hasLabel(textOutput, 'Particulars')) missing.add('Particulars');
      if (!_hasLabel(textOutput, 'Mode')) missing.add('Mode');

      if (missing.isNotEmpty) return _insufficientAlert(missing);

      return textOutput.trim();
    } catch (e) {
      return _insufficientAlert(['Recipient', 'Purpose', 'Particulars', 'Mode']);
    }
  }

  // Helper: check if a labelled field exists in multiline text
  bool _hasLabel(String text, String label) {
    final regex = RegExp(r'^\s*' + RegExp.escape(label) + r'\s*[:\-]', caseSensitive: false, multiLine: true);
    return regex.hasMatch(text);
  }

  String _insufficientAlert(List<String> missing) {
    final joined = missing.join(', ');
    return 'ALERT: Insufficient Information. Please provide the following details to complete the disclosure: $joined';
  }
}
