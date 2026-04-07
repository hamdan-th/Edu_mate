// lib/core_api_service.dart

import 'dart:convert'; // لتحويل استجابة الـ API من نص إلى كائن
import 'package:http/http.dart' as http; // حزمة http التي أضفناها

class CoreApiService {
  // 1. --- المتغيرات الأساسية ---

  // الرابط الأساسي للـ API. من وثائق CORE API v3.
  static const String _baseUrl = 'https://api.core.ac.uk/v3/search/works';

  // مفتاح الـ API الخاص بك الذي حصلت عليه.
  // ✨ مهم جداً: لا ترفع هذا المفتاح إلى مستودع عام مثل GitHub.
  static const String _apiKey = '39wzkFCQL0BNKRjuGIpliEqorZxtTVd2';
  // lib/core_api_service.dart

// ... (بعد دالة search)

// دالة جديدة لجلب الرابط القابل للفتح من رابط الـ output
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
        // من خلال التجربة، الرابط النهائي يكون في مفتاح "downloadUrl"
        return data['downloadUrl'];
      }
      return null;
    } catch (e) {
      print('Failed to get downloadable link: $e');
      return null;
    }
  }



  // 2. --- دالة البحث الرئيسية ---

  // هذه هي الدالة التي ستستدعيها واجهة المستخدم.
  // هي من نوع `Future` لأنها عملية غير متزامنة (تستغرق وقتاً ).
  static Future<List<dynamic>> search(String query) async {
    // بناء الاستعلام الكامل كما هو مطلوب في وثائق CORE.
    // نحن نبحث في العنوان والملخص والمؤلفين.
    final String searchQuery = 'title:("$query") OR abstract:("$query") OR authors:("$query")';

    // بناء رابط الطلب (URL) النهائي مع الاستعلام.
    // `Uri.parse` تتأكد من أن الرابط مهيأ بشكل صحيح.
    final Uri url = Uri.parse(_baseUrl);

    try {
      // 3. --- إرسال الطلب ---

      // `http.post` لإرسال طلب من نوع POST كما توصي وثائق CORE v3.
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // نوع المحتوى الذي نرسله
          'Authorization': 'Bearer $_apiKey', // ✨ هنا نضع مفتاح الـ API للمصادقة
        },
        // جسم الطلب (Body ) بتنسيق JSON.
        // نرسل الاستعلام ونطلب 20 نتيجة كحد أقصى.
        body: jsonEncode({
          'q': searchQuery,
          'limit': 20,
        }),
      );

      // 4. --- معالجة الاستجابة ---

      // التحقق من أن الطلب كان ناجحاً (رمز الحالة 200 يعني "OK").
      if (response.statusCode == 200) {
        // `jsonDecode` يقوم بتحويل النص القادم من الخادم (بتنسيق JSON) إلى كائن Dart.
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        // من خلال قراءة الوثائق، نعلم أن النتائج موجودة داخل مفتاح يسمى "results".
        // نتحقق من وجودها وأنها ليست فارغة.
        if (data.containsKey('results') && data['results'] is List) {
          return data['results']; // نرجع قائمة النتائج
        } else {
          return []; // إذا لم توجد نتائج، نرجع قائمة فارغة
        }
      } else {
        // إذا فشل الطلب (مثلاً، خطأ في الخادم أو مفتاح API خاطئ).
        print('API call failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return []; // نرجع قائمة فارغة في حالة الخطأ
      }
    } catch (e) {
      // للتعامل مع أخطاء الشبكة (مثلاً، لا يوجد اتصال بالإنترنت).
      print('An error occurred during the API call: $e');
      return []; // نرجع قائمة فارغة في حالة الخطأ
    }
  }
}
