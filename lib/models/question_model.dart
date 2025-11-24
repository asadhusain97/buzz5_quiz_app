/// Enum to track the status of a Question.
enum QuestionStatus { draft, published }

class Question {
  final String id;
  final String? questionText;
  final String? questionMedia; // URL to media in Firebase Storage
  final String? answerText;
  final String? answerMedia; // URL to media in Firebase Storage
  final int points;
  final String? hint;
  final String? funda; // Explanation of the concept
  late final QuestionStatus status;

  Question({
    required this.id,
    this.questionText,
    this.questionMedia,
    this.answerText,
    this.answerMedia,
    this.points = 10,
    this.hint,
    this.funda,
    QuestionStatus? status,
  }) {
    // Validate that question has either text or media
    final hasValidQuestion = questionText != null || questionMedia != null;
    // Validate that answer has either text or media
    final hasValidAnswer = answerText != null || answerMedia != null;

    // Set status to draft if validation fails, otherwise use provided status or draft
    if (!hasValidQuestion || !hasValidAnswer) {
      this.status = QuestionStatus.draft;
    } else {
      this.status = status ?? QuestionStatus.draft;
    }
  }

  // Factory constructor to create a Question from a JSON object
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String?,
      questionMedia: json['questionMedia'] as String?,
      answerText: json['answerText'] as String?,
      answerMedia: json['answerMedia'] as String?,
      points: json['points'] as int? ?? 10,
      hint: json['hint'] as String?,
      funda: json['funda'] as String?,
      status: QuestionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => QuestionStatus.draft,
      ),
    );
  }

  // Method to convert a Question object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'questionMedia': questionMedia,
      'answerText': answerText,
      'answerMedia': answerMedia,
      'points': points,
      'hint': hint,
      'funda': funda,
      'status': status.toString(),
    };
  }
}
