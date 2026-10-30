
import 'package:flutter/material.dart';

import 'data/repositories/practice_repository.dart';
import 'data/services/api_failure.dart';
import 'domain/models/question.dart';
import 'utils/result.dart';

Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return PracticeAppRoot(
    repository: repository,
    studentId: studentId,
  );
}

class PracticeAppRoot extends StatefulWidget {
  const PracticeAppRoot({
    super.key,
    required this.repository,
    required this.studentId,
  });

  final PracticeRepository repository;
  final String studentId;

  @override
  State<PracticeAppRoot> createState() => _PracticeAppRootState();
}

class _PracticeAppRootState extends State<PracticeAppRoot> {
  late final PracticeController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PracticeController(
      repository: widget.repository,
      studentId: widget.studentId,
    );

    _controller.loadQuestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PracticeScreen(controller: _controller),
    );
  }
}

class PracticeController extends ChangeNotifier {
  PracticeController({
    required PracticeRepository repository,
    required String studentId,
  })  : _repository = repository,
        _studentId = studentId;

  final PracticeRepository _repository;
  final String _studentId;

  bool isLoading = true;
  bool _requestInProgress = false;
  bool _disposed = false;

  List<Question> questions = [];
  ApiFailure? failure;

  Future<void> loadQuestions() async {
    if (_requestInProgress || _disposed) return;

    _requestInProgress = true;
    isLoading = true;
    failure = null;

    notifyListeners();

    try {
      final result = await _repository.nextQuestions(_studentId);

      if (_disposed) return;

      if (result is Ok<List<Question>>) {
        questions = result.value;
        failure = null;
      } else if (result is Err<List<Question>>) {
        failure = result.failure;
        questions = [];
      }
    } finally {
      if (!_disposed) {
        isLoading = false;
        _requestInProgress = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({
    super.key,
    required this.controller,
  });

  final PracticeController controller;

  String _failureMessage(ApiFailure failure) {
    if (failure is Unauthorized) {
      return 'Please sign in to continue.';
    }

    if (failure is NotFound) {
      return 'Student account was not found.';
    }

    if (failure is Offline) {
      return 'No internet connection. Check your connection and try again.';
    }

    if (failure is TimedOut) {
      return 'The request took too long. Please try again.';
    }

    if (failure is RateLimited) {
      return 'Too many requests. Please wait and try again.';
    }

    if (failure is ServerError) {
      return 'The server is temporarily unavailable.';
    }

    if (failure is BadResponse) {
      return 'We could not load the questions. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Practice'),
            actions: [
              IconButton(
                key: const Key('practice-refresh'),
                tooltip: 'Refresh',
                onPressed: controller.isLoading
                    ? null
                    : controller.loadQuestions,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        key: Key('practice-loading'),
        child: CircularProgressIndicator(),
      );
    }

    final failure = controller.failure;

    if (failure != null) {
      return _buildFailureView(failure);
    }

    if (controller.questions.isEmpty) {
      return const Center(
        key: Key('practice-empty'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "You have finished today's practice.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      key: const Key('practice-list'),
      padding: const EdgeInsets.all(16),
      itemCount: controller.questions.length,
      itemBuilder: (context, index) {
        final question = controller.questions[index];

        return Card(
          key: Key('question-${question.id}'),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.stem,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...question.choices.map(
                  (choice) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(choice),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFailureView(ApiFailure failure) {
    final isUnauthorized = failure is Unauthorized;

    return Center(
      key: const Key('practice-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _failureMessage(failure),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isUnauthorized)
              ElevatedButton(
                key: const Key('practice-signin'),
                onPressed: () {},
                child: const Text('Sign in'),
              )
            else
              ElevatedButton(
                key: const Key('practice-retry'),
                onPressed: controller.loadQuestions,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
