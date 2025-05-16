import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const _endpoint =
      "https://models.github.ai/inference/chat/completions";

  static Future<String> askAI(String instruction, String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['BOA_API_KEY']}',
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "developer",
              "content": instruction,
              },
            {"role": "user", "content": prompt},
          ],
          "model": "openai/gpt-4o-mini",
          "temperature": 1,
          "max_tokens": 4096
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure the response contains the expected keys
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ??
              'No response content';
        } else {
          return 'No response available from the model';
        }
      } else {
        throw Exception('API call failed: ${response.body}');
      }
    } catch (e) {
      // Return a fallback error message in case of any exception
      return 'Error occurred: $e';
    }
  }
}
