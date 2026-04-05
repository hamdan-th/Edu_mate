import 'package:cloud_functions/cloud_functions.dart';
import '../models/edu_bot_message_model.dart';

class EduBotService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<String> sendMessage(String message, {List<EduBotMessageModel>? history}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('eduBot');
      
      final List<Map<String, String>>? historyPayload = history?.map((msg) => {
        'role': msg.isUser ? 'user' : 'model',
        'text': msg.text,
      }).toList();

      final results = await callable.call(<String, dynamic>{
        'message': message,
        if (historyPayload != null) 'history': historyPayload,
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
