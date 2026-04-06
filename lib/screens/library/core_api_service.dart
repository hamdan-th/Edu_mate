// lib/core_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class CoreApiService {
  static const String _baseUrl = 'https://api.core.ac.uk/v3/search/works';
  static const String _apiKey = '39wzkFCQL0BNKRjuGIpliEqorZxtTVd2';

  static Future<String?> getDownloadableLink(String outputUrl) async {
    try {
      final response = await http.get(
        Uri.parse(outputUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return data['downloadUrl'];
      }
      return null;
    } catch (e) {
      print('Failed to get downloadable link: $e');
      return null;
    }
  }

  static Future<List<dynamic>> search(String query) async {
    final String searchQuery =
        'title:("$query") OR abstract:("$query") OR authors:("$query")';

    final Uri url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'q': searchQuery,
          'limit': 20,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));

        if (data.containsKey('results') && data['results'] is List) {
          return data['results'];
        } else {
          return [];
        }
      } else {
        print('API call failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('An error occurred during the API call: $e');
      return [];
    }
  }
}
