import 'package:cloud_functions/cloud_functions.dart';
import '../models/edu_bot_message_model.dart';

class EduBotService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  static Future<String> sendMessage(String message, {List<EduBotMessageModel>? history}) async {
    int attempts = 0;
    while (attempts < 2) {
      try {
        final HttpsCallable callable = _functions.httpsCallable(
          'eduBot',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        );
        
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
        if (attempts == 0 && (e.code == 'unavailable' || e.code == 'deadline-exceeded' || e.code == 'internal')) {
          print("Retrying eduBot call due to transient failure (${e.code})...");
          attempts++;
          continue;
        }
        return "عذراً، حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقاً.";
      } catch (e) {
        print("Edu Bot Service Error: $e");
        return "عذراً، واجهنا مشكلة تقنية. يرجى التأكد من اتصالك بالإنترنت والمحاولة مجدداً.";
      }
    }
    return "عذراً، حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقاً.";
  }
}
