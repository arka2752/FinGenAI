import 'dart:convert';
import 'package:http/http.dart' as http;


class DeepSeekService {
  // Replace with your OpenRouter API key (keep it secret!)
  final String apiKey = "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";

  // OpenRouter endpoint for chat completions
  final String baseUrl = "https://openrouter.ai/api/v1/chat/completions";

  /// Sends user input to DeepSeek R1 0528 (free) and returns AI response
  Future<String> sendPrompt(String prompt) async {
    if (prompt.trim().isEmpty) {
      return "Please provide a valid prompt.";
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-r1-0528:free", // DeepSeek model
          "messages": [
            {"role": "user", "content": prompt}
          ],
          // Optional metadata
          "extra_headers": {
            "HTTP-Referer": "https://yourapp.com",
            "X-Title": "FingenAI App"
          },
          "extra_body": {}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Make sure the structure exists before accessing
        final choices = data["choices"];
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]["message"]?["content"];
          return content ?? "No response from AI.";
        } else {
          return "AI returned empty response.";
        }
      } else if (response.statusCode == 401) {
        return "Unauthorized: Check your API key.";
      } else {
        return "Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }
}
