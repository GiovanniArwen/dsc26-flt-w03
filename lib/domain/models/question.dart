/// One practice question chosen for a student by the Masaraat backend.
final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  factory Question.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final skillId = json['skillId'];
    final stem = json['stem'];
    final choices = json['choices'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Invalid question id');
    }

    if (skillId is! String || skillId.trim().isEmpty) {
      throw const FormatException('Invalid skillId');
    }

    if (stem is! String || stem.trim().isEmpty) {
      throw const FormatException('Invalid question stem');
    }

    if (choices is! List || choices.length < 2 || choices.length > 6) {
      throw const FormatException('Invalid question choices');
    }

    final parsedChoices = <String>[];

    for (final choice in choices) {
      if (choice is! String || choice.trim().isEmpty) {
        throw const FormatException('Invalid choice');
      }

      parsedChoices.add(choice);
    }

    return Question(
      id: id,
      skillId: skillId,
      stem: stem,
      choices: List.unmodifiable(parsedChoices),
    );
  }
}
