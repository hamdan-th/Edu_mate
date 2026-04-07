// lib/core_api_service.dart

import 'dart:convert'; // ظ„طھط­ظˆظٹظ„ ط§ط³طھط¬ط§ط¨ط© ط§ظ„ظ€ API ظ…ظ† ظ†طµ ط¥ظ„ظ‰ ظƒط§ط¦ظ†
import 'package:http/http.dart' as http; // ط­ط²ظ…ط© http ط§ظ„طھظٹ ط£ط¶ظپظ†ط§ظ‡ط§

class CoreApiService {
  // 1. --- ط§ظ„ظ…طھط؛ظٹط±ط§طھ ط§ظ„ط£ط³ط§ط³ظٹط© ---

  // ط§ظ„ط±ط§ط¨ط· ط§ظ„ط£ط³ط§ط³ظٹ ظ„ظ„ظ€ API. ظ…ظ† ظˆط«ط§ط¦ظ‚ CORE API v3.
  static const String _baseUrl = 'https://api.core.ac.uk/v3/search/works';

  // ظ…ظپطھط§ط­ ط§ظ„ظ€ API ط§ظ„ط®ط§طµ ط¨ظƒ ط§ظ„ط°ظٹ ط­طµظ„طھ ط¹ظ„ظٹظ‡.
  // âœ¨ ظ…ظ‡ظ… ط¬ط¯ط§ظ‹: ظ„ط§ طھط±ظپط¹ ظ‡ط°ط§ ط§ظ„ظ…ظپطھط§ط­ ط¥ظ„ظ‰ ظ…ط³طھظˆط¯ط¹ ط¹ط§ظ… ظ…ط«ظ„ GitHub.
  static const String _apiKey = '39wzkFCQL0BNKRjuGIpliEqorZxtTVd2';
  // lib/core_api_service.dart

// ... (ط¨ط¹ط¯ ط¯ط§ظ„ط© search)

// ط¯ط§ظ„ط© ط¬ط¯ظٹط¯ط© ظ„ط¬ظ„ط¨ ط§ظ„ط±ط§ط¨ط· ط§ظ„ظ‚ط§ط¨ظ„ ظ„ظ„ظپطھط­ ظ…ظ† ط±ط§ط¨ط· ط§ظ„ظ€ output
  static Future<String?> getDownloadableLink(String outputUrl) async {
    try {
      final response = await http.get(
        Uri.parse(outputUrl ),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        // ظ…ظ† ط®ظ„ط§ظ„ ط§ظ„طھط¬ط±ط¨ط©طŒ ط§ظ„ط±ط§ط¨ط· ط§ظ„ظ†ظ‡ط§ط¦ظٹ ظٹظƒظˆظ† ظپظٹ ظ…ظپطھط§ط­ "downloadUrl"
        return data['downloadUrl'];
      }
      return null;
    } catch (e) {
      print('Failed to get downloadable link: $e');
      return null;
    }
  }



  // 2. --- ط¯ط§ظ„ط© ط§ظ„ط¨ط­ط« ط§ظ„ط±ط¦ظٹط³ظٹط© ---

  // ظ‡ط°ظ‡ ظ‡ظٹ ط§ظ„ط¯ط§ظ„ط© ط§ظ„طھظٹ ط³طھط³طھط¯ط¹ظٹظ‡ط§ ظˆط§ط¬ظ‡ط© ط§ظ„ظ…ط³طھط®ط¯ظ….
  // ظ‡ظٹ ظ…ظ† ظ†ظˆط¹ `Future` ظ„ط£ظ†ظ‡ط§ ط¹ظ…ظ„ظٹط© ط؛ظٹط± ظ…طھط²ط§ظ…ظ†ط© (طھط³طھط؛ط±ظ‚ ظˆظ‚طھط§ظ‹ ).
  static Future<List<dynamic>> search(String query) async {
    // ط¨ظ†ط§ط، ط§ظ„ط§ط³طھط¹ظ„ط§ظ… ط§ظ„ظƒط§ظ…ظ„ ظƒظ…ط§ ظ‡ظˆ ظ…ط·ظ„ظˆط¨ ظپظٹ ظˆط«ط§ط¦ظ‚ CORE.
    // ظ†ط­ظ† ظ†ط¨ط­ط« ظپظٹ ط§ظ„ط¹ظ†ظˆط§ظ† ظˆط§ظ„ظ…ظ„ط®طµ ظˆط§ظ„ظ…ط¤ظ„ظپظٹظ†.
    final String searchQuery = 'title:("$query") OR abstract:("$query") OR authors:("$query")';

    // ط¨ظ†ط§ط، ط±ط§ط¨ط· ط§ظ„ط·ظ„ط¨ (URL) ط§ظ„ظ†ظ‡ط§ط¦ظٹ ظ…ط¹ ط§ظ„ط§ط³طھط¹ظ„ط§ظ….
    // `Uri.parse` طھطھط£ظƒط¯ ظ…ظ† ط£ظ† ط§ظ„ط±ط§ط¨ط· ظ…ظ‡ظٹط£ ط¨ط´ظƒظ„ طµط­ظٹط­.
    final Uri url = Uri.parse(_baseUrl);

    try {
      // 3. --- ط¥ط±ط³ط§ظ„ ط§ظ„ط·ظ„ط¨ ---

      // `http.post` ظ„ط¥ط±ط³ط§ظ„ ط·ظ„ط¨ ظ…ظ† ظ†ظˆط¹ POST ظƒظ…ط§ طھظˆطµظٹ ظˆط«ط§ط¦ظ‚ CORE v3.
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // ظ†ظˆط¹ ط§ظ„ظ…ط­طھظˆظ‰ ط§ظ„ط°ظٹ ظ†ط±ط³ظ„ظ‡
          'Authorization': 'Bearer $_apiKey', // âœ¨ ظ‡ظ†ط§ ظ†ط¶ط¹ ظ…ظپطھط§ط­ ط§ظ„ظ€ API ظ„ظ„ظ…طµط§ط¯ظ‚ط©
        },
        // ط¬ط³ظ… ط§ظ„ط·ظ„ط¨ (Body ) ط¨طھظ†ط³ظٹظ‚ JSON.
        // ظ†ط±ط³ظ„ ط§ظ„ط§ط³طھط¹ظ„ط§ظ… ظˆظ†ط·ظ„ط¨ 20 ظ†طھظٹط¬ط© ظƒط­ط¯ ط£ظ‚طµظ‰.
        body: jsonEncode({
          'q': searchQuery,
          'limit': 20,
        }),
      );

      // 4. --- ظ…ط¹ط§ظ„ط¬ط© ط§ظ„ط§ط³طھط¬ط§ط¨ط© ---

      // ط§ظ„طھط­ظ‚ظ‚ ظ…ظ† ط£ظ† ط§ظ„ط·ظ„ط¨ ظƒط§ظ† ظ†ط§ط¬ط­ط§ظ‹ (ط±ظ…ط² ط§ظ„ط­ط§ظ„ط© 200 ظٹط¹ظ†ظٹ "OK").
      if (response.statusCode == 200) {
        // `jsonDecode` ظٹظ‚ظˆظ… ط¨طھط­ظˆظٹظ„ ط§ظ„ظ†طµ ط§ظ„ظ‚ط§ط¯ظ… ظ…ظ† ط§ظ„ط®ط§ط¯ظ… (ط¨طھظ†ط³ظٹظ‚ JSON) ط¥ظ„ظ‰ ظƒط§ط¦ظ† Dart.
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        // ظ…ظ† ط®ظ„ط§ظ„ ظ‚ط±ط§ط،ط© ط§ظ„ظˆط«ط§ط¦ظ‚طŒ ظ†ط¹ظ„ظ… ط£ظ† ط§ظ„ظ†طھط§ط¦ط¬ ظ…ظˆط¬ظˆط¯ط© ط¯ط§ط®ظ„ ظ…ظپطھط§ط­ ظٹط³ظ…ظ‰ "results".
        // ظ†طھط­ظ‚ظ‚ ظ…ظ† ظˆط¬ظˆط¯ظ‡ط§ ظˆط£ظ†ظ‡ط§ ظ„ظٹط³طھ ظپط§ط±ط؛ط©.
        if (data.containsKey('results') && data['results'] is List) {
          return data['results']; // ظ†ط±ط¬ط¹ ظ‚ط§ط¦ظ…ط© ط§ظ„ظ†طھط§ط¦ط¬
        } else {
          return []; // ط¥ط°ط§ ظ„ظ… طھظˆط¬ط¯ ظ†طھط§ط¦ط¬طŒ ظ†ط±ط¬ط¹ ظ‚ط§ط¦ظ…ط© ظپط§ط±ط؛ط©
        }
      } else {
        // ط¥ط°ط§ ظپط´ظ„ ط§ظ„ط·ظ„ط¨ (ظ…ط«ظ„ط§ظ‹طŒ ط®ط·ط£ ظپظٹ ط§ظ„ط®ط§ط¯ظ… ط£ظˆ ظ…ظپطھط§ط­ API ط®ط§ط·ط¦).
        print('API call failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return []; // ظ†ط±ط¬ط¹ ظ‚ط§ط¦ظ…ط© ظپط§ط±ط؛ط© ظپظٹ ط­ط§ظ„ط© ط§ظ„ط®ط·ط£
      }
    } catch (e) {
      // ظ„ظ„طھط¹ط§ظ…ظ„ ظ…ط¹ ط£ط®ط·ط§ط، ط§ظ„ط´ط¨ظƒط© (ظ…ط«ظ„ط§ظ‹طŒ ظ„ط§ ظٹظˆط¬ط¯ ط§طھطµط§ظ„ ط¨ط§ظ„ط¥ظ†طھط±ظ†طھ).
      print('An error occurred during the API call: $e');
      return []; // ظ†ط±ط¬ط¹ ظ‚ط§ط¦ظ…ط© ظپط§ط±ط؛ط© ظپظٹ ط­ط§ظ„ط© ط§ظ„ط®ط·ط£
    }
  }
}

