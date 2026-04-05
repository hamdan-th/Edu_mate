import 'package:cloud_functions/cloud_functions.dart';

class BotRemoteService {
  final FirebaseFunctions _functions;

  BotRemoteService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<String> sendToBot(String message, List<Map<String, String>> historyPayload) async {
    try {
      final callable = _functions.httpsCallable(
        'eduBot',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final results = await callable.call(<String, dynamic>{
        'message': message,
        if (historyPayload.isNotEmpty) 'history': historyPayload,
      });

      final data = results.data as Map<String, dynamic>?;
      if (data != null && data.containsKey('reply')) {
        return data['reply'].toString();
      }
      throw Exception("عذراً، لم أتمكن من معالجة الرد.");
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقاً.");
    } catch (e) {
      throw Exception("واجهنا مشكلة تقنية. يرجى التأكد من اتصالك بالإنترنت والمحاولة مجدداً.");
    }
  }
}
