import '../../domain/models/question.dart';
import '../../utils/result.dart';
import '../services/api_failure.dart';
import '../services/question_api.dart';

class PracticeRepository {
PracticeRepository({
  required this._api,
  required this._sleep,
  this._maxRetries = 2,
});

  final QuestionApi _api;
  final Future<void> Function(Duration) _sleep;
  final int _maxRetries;

  Future<Result<List<Question>>> nextQuestions(String studentId) async {
    var attempt = 0;

    while (true) {
      final result = await _api.fetchNext(
        studentId: studentId,
      );

      if (result is Ok<List<Question>>) {
        return result;
      }

      final failure = (result as Err<List<Question>>).failure;

      // Permanent failures should not be retried.
      if (!failure.isTransient || attempt >= _maxRetries) {
        return result;
      }

      Duration waitDuration;

      if (failure is RateLimited) {
        final retryAfter = failure.retryAfter;
        const maxWait = Duration(seconds: 30);

        waitDuration = retryAfter > maxWait ? maxWait : retryAfter;
      } else {
        waitDuration = Duration(seconds: 1 << attempt);
      }

      await _sleep(waitDuration);

      attempt++;
    }
  }
}