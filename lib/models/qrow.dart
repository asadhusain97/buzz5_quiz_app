import 'package:buzz5_quiz_app/models/set_model.dart';

/// Model representing a question row for the quiz board.
///
/// This is a flat data structure used by QuestionBoardPage and related components.
/// It can be created from Firebase data using the [QRow.fromFirebase] factory.
class QRow {
  final int qid;
  final String round;
  final String setName;
  final int points;
  final String question;
  final String qstnMedia;
  final dynamic answer;
  final String ansMedia;
  final String setExplanation;

  QRow({
    required this.qid,
    required this.round,
    required this.setName,
    required this.points,
    required this.question,
    required this.qstnMedia,
    required this.answer,
    required this.ansMedia,
    this.setExplanation = "This category covers various topics and themes.",
  });

  /// Factory constructor to create a QRow from Firebase data.
  ///
  /// This transforms the hierarchical Firebase structure (Board -> Set -> Question)
  /// into the flat QRow format expected by QuestionBoardPage.
  ///
  /// Parameters:
  /// - qid: Unique question ID (generated sequentially)
  /// - boardName: The board name (becomes 'round')
  /// - setModel: The SetModel containing set metadata
  /// - questionText: The question text (can be null/empty if media is present)
  /// - questionMediaUrl: URL for question media (can be null)
  /// - answerText: The answer text (can be null/empty if media is present)
  /// - answerMediaUrl: URL for answer media (can be null)
  /// - points: Point value for this question
  factory QRow.fromFirebase({
    required int qid,
    required String boardName,
    required SetModel setModel,
    String? questionText,
    String? questionMediaUrl,
    String? answerText,
    String? answerMediaUrl,
    required int points,
  }) {
    return QRow(
      qid: qid,
      round: boardName,
      setName: setModel.name,
      points: points,
      question: questionText ?? '',
      qstnMedia: questionMediaUrl ?? '',
      answer: answerText ?? '',
      ansMedia: answerMediaUrl ?? '',
      setExplanation: setModel.description,
    );
  }

  static List<QRow> filterByRound(List<QRow> qrows, String round) {
    return qrows.where((qrow) => qrow.round == round).toList();
  }

  static List<QRow> filterBySetName(List<QRow> qrows, String setName) {
    return qrows.where((qrow) => qrow.setName == setName).toList();
  }

  static List<String> getUniqueRounds(List<QRow> qrows) {
    return qrows.map((qrow) => qrow.round).toSet().toList();
  }

  static List<String> getUniqueSetNames(List<QRow> qrows) {
    return qrows.map((qrow) => qrow.setName).toSet().toList();
  }
}
