import 'dart:convert';
import 'package:allen/secrets.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  final List<Map<String,String>> messages = [];
  //tell us whether user wants to generate an art or not
  Future<String> isArtPromptAPI(String prompt) async {
    print(prompt);
    try {
      final res = await http.post(
        Uri.parse(
          'https://api.openai.com/v1/chat/completions'
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey'
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role' : 'user',
              'content' : 'Does this message want an image? "$prompt". Simply answer with a Yes or No',
            }
          ]
        }),
      );
      print(res.statusCode);
      if(res.statusCode == 200) {
        String content = 
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        switch(content) {
          case 'Yes':
          case 'yes':
          case 'Yes.':
          case 'yes.':
            final res = await dallEAPI(prompt);
            return res;
          default: 
            final res = await ChatGPTAPI(prompt);
            return res;
        }
      }
      return 'Rai randi';
    } catch(e) {
      return e.toString();
    }
  }
  //ChatGPT response
  Future<String> ChatGPTAPI(String prompt) async {

     messages.add({
      'role': 'user',
      'content': prompt,
    });
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }),
      );

      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        messages.add({
          'role': 'assistant',
          'content': content,
        });
        return content;
      }
      return 'An internal error occurred';
    } catch (e) {
      return e.toString();
    }
  }
  //Dall-E response
  Future<String> dallEAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n' : 1
        }),
      );

      if (res.statusCode == 200) {
        String imageURL = jsonDecode(res.body)['data'][0]['url'];
        imageURL = imageURL.trim();

        messages.add({
          'role': 'assistant',
          'content': imageURL,
        });
        return imageURL;
      }
      return 'An internal error occurred';
    } catch (e) {
      return e.toString();
    }
  }
}