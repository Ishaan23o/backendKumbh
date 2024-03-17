import 'package:google_generative_ai/google_generative_ai.dart';
final getInstructions=(String description) async {
  try {
    final apiKey = 'AIzaSyA-M0FTnMwIL_IJCarBmRsTJ8l6T2yBgjg';
    if (apiKey == null) {
      return "NO API_KEY FOUND";
    }
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final content = [Content.text('You are part of an app for kumbh mela pilgrims. One user has entered a complaint with description: $description. Please write some general instructions or precautions he can take which will not interfere with the law enforcement and will help resolve them. Your goal is to be brief and just give text, no formatting')];
    final response = await model.generateContent(content);
    return response.text;
  }catch(err){
    return 'Some Error Occured';
  }
};