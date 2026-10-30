
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import '../../utils/result.dart';
import 'api_failure.dart';

class QuestionApi {
QuestionApi({
  required this._client,
  required this._baseUrl,
  this._timeout = const Duration(seconds: 10),
});

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  Future<Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Must be between 1 and 50',
      );
    }

    final baseSegments = _baseUrl.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();

    final uri = _baseUrl.replace(
      pathSegments: [
        ...baseSegments,
        'v1',
        'students',
        studentId,
        'next-questions',
      ],
      queryParameters: {
        'limit': '$limit',
      },
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(Unauthorized());
      }

      if (response.statusCode == 404) {
        return Err(NotFound());
      }

      if (response.statusCode == 429) {
        final retryHeader = response.headers['retry-after'];

        final seconds = retryHeader != null &&
                RegExp(r'^\d+$').hasMatch(retryHeader.trim())
            ? int.tryParse(retryHeader.trim()) ?? 5
            : 5;

        return Err(
          RateLimited(Duration(seconds: seconds)),
        );
      }

      if (response.statusCode >= 500 &&
          response.statusCode <= 599) {
        return Err(ServerError(response.statusCode));
      }

      if (response.statusCode != 200) {
        return Err(UnexpectedStatus(response.statusCode));
      }

      try {
        final body = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(body);

        if (decoded is! Map || decoded['questions'] is! List) {
          return Err(BadResponse('Invalid response structure'));
        }

        final rawQuestions = decoded['questions'] as List;
        final questions = <Question>[];

        for (final item in rawQuestions) {
          if (item is! Map) {
            return Err(BadResponse('Invalid question object'));
          }

          final question = Question.fromJson(
            Map<String, Object?>.from(item),
          );

          questions.add(question);
        }

        return Ok(List.unmodifiable(questions));
      } on FormatException {
        return Err(BadResponse('Invalid JSON response'));
      } on TypeError {
        return Err(BadResponse('Invalid response data'));
      } on ArgumentError {
        return Err(BadResponse('Invalid response fields'));
      }
    } on TimeoutException {
      return Err(TimedOut());
    } on http.ClientException {
      return Err(Offline());
    }
  }
}
