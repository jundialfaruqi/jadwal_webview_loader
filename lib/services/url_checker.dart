import 'package:http/http.dart' as http;

Future<bool> isValidUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'});
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
