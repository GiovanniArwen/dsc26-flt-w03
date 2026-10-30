# AI Usage: dsc26-flt-w03

## 1. Tools I used

- ChatGPT: Used to understand task requirements, discuss implementation approaches, review code, and troubleshoot errors.
- Visual Studio Code: Used to write and edit Dart files.
- FVM: Used to manage the required Flutter SDK version.
- Flutter test runner: Used to run the provided public tests and verify the implementation.

## 2. The prompts that helped most

1. "Help me implement the QuestionApi according to the task requirements, including URL construction, response parsing, UTF-8 decoding, HTTP status handling, and network error handling."

2. "Review my retry logic and Flutter UI against the task requirements. Help me handle transient failures, Retry-After, loading states, refresh actions, and widget disposal safely."

## 3. Where the assistant's code would have failed a hidden-test area, and how I noticed

During implementation, the initial QuestionApi implementation was still incomplete and threw an UnimplementedError. Running the provided public tests exposed this immediately because the API tests failed before reaching the expected response handling. I implemented fetchNext and ran the tests again until all five public tests passed.

I also reviewed additional response-validation cases, including malformed JSON, invalid UTF-8, and invalid question fields, to make sure they return BadResponse rather than throwing parsing errors. These checks relate to H03 and H04.

## 4. My state-management choice

I chose ChangeNotifier because it keeps the loading, success, empty, and error states in one controller, while allowing the UI to listen to changes without adding unnecessary state-management complexity.