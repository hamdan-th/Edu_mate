import 'package:cloud_functions/cloud_functions.dart';

class EduBotService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<String> sendMessage(String message) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('eduBot');
      final results = await callable.call(<String, dynamic>{
        'message': message,
      });

      final data = results.data as Map<String, dynamic>?;
      if (data != null && data.containsKey('reply')) {
        return data['reply'].toString();
      }
      return "عذراً، لم أتمكن من معالجة الرد.";
    } on FirebaseFunctionsException catch (e) {
      print("FirebaseFunctionsException: ${e.code} - ${e.message}");
      return "عذراً، حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقاً.";
    } catch (e) {
      print("Edu Bot Service Error: $e");
      return "عذراً، واجهنا مشكلة تقنية. يرجى التأكد من اتصالك بالإنترنت والمحاولة مجدداً.";
    }
  }
}
