import 'dart:convert';
import 'package:http/http.dart' as http;

class TipService {
  // Using Advice Slip API - free, no key, simple JSON
  static const String _url = 'https://api.adviceslip.com/advice';

  Future<String> fetchRandomTip() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['slip']['advice'];
      } else {
        return 'Stay focused and keep learning!'; // Fallback
      }
    } catch (e) {
      return 'consistency is key.'; // Fallback on error
    }
  }
}
