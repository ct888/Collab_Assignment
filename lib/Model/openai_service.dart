import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apikey.dart';

class OpenAIService {
  static const _endpoint =
      "https://models.inference.ai.azure.com/chat/completions";

  static List<String> instruction = [
    "You are now a book of answer that will provide a short quote to user prompt.",
    "The quote must be less than 10 words",
    "The quote must be relevant to the prompt if it was given",
    "If there is no prompt, give a general quote that might help someone who is adapting to new environment."
  ];

  static Future<String> askAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Apikey.APIKey}',
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "developer",
              "content": instruction.join('\n'),
              },
            {"role": "user", "content": prompt},
          ],
          "model": "gpt-4o",
          "temperature": 1,
          "max_tokens": 4096,
          "top_p": 1,
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
