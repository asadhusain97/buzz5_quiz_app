import 'package:buzz5_quiz_app/models/media_model.dart';

/// Enum to track the status of a Question.
/// - complete: Question has both question and answer (text or media)
/// - draft: Question is incomplete
enum QuestionStatus { draft, complete }

class Question {
  final String id;
  final String? questionText;
  final Media? questionMedia; // Media object with metadata
  final String? answerText;
  final Media? answerMedia; // Media object with metadata
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
    final hasValidQuestion =
        (questionText != null && questionText!.trim().isNotEmpty) ||
        questionMedia != null;
    // Validate that answer has either text or media
    final hasValidAnswer =
        (answerText != null && answerText!.trim().isNotEmpty) ||
        answerMedia != null;

    // Set status to complete if validation passes, otherwise draft
    if (hasValidQuestion && hasValidAnswer) {
      this.status = status ?? QuestionStatus.complete;
    } else {
      this.status = QuestionStatus.draft;
    }
  }

  // Factory constructor to create a Question from a JSON object
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String?,
      questionMedia: json['questionMedia'] != null
          ? Media.fromJson(json['questionMedia'] as Map<String, dynamic>)
          : null,
      answerText: json['answerText'] as String?,
      answerMedia: json['answerMedia'] != null
          ? Media.fromJson(json['answerMedia'] as Map<String, dynamic>)
          : null,
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
      'questionMedia': questionMedia?.toJson(),
      'answerText': answerText,
      'answerMedia': answerMedia?.toJson(),
      'points': points,
      'hint': hint,
      'funda': funda,
      'status': status.toString(),
    };
  }
}
