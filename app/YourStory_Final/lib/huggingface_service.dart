import 'dart:convert';
import 'package:http/http.dart' as http;

class HuggingFaceService {
  final String apiKey = "YOUR_HUGGING_FACE_API_KEY";
  final String modelUrl = "https://api-inference.huggingface.co/models/abdalraheemdmd/story-api";

  // You can optionally pass in an API key through the constructor.
  // HuggingFaceService({ required this.apiKey, required this.modelUrl });

  Future<String> generateStory(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"inputs": prompt}),
      );

      if (response.statusCode == 200) {
        // The response can be an array of results or a JSON object depending on the model
        var jsonResponse = jsonDecode(response.body);

        // Adjust this line depending on how your model is returning text
        // Often it's something like jsonResponse[0]["generated_text"]
        String generatedText = jsonResponse[0]["generated_text"];
        return generatedText;
      } else {
        // Return a helpful error message
        throw Exception("Failed to generate story. Response code: ${response.statusCode}\nBody: ${response.body}");
      }
    } catch (e) {
      // For debugging/logging
      print("Error in generateStory: $e");
      rethrow;
    }
  }
}
