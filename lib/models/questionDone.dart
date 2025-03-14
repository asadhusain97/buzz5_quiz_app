import 'package:flutter/foundation.dart';

class AnsweredQuestionsProvider with ChangeNotifier {
  // Set to store unique IDs of answered questions
  final Set<String> _answeredQuestions = {};

  // Check if a question is answered
  bool isQuestionAnswered(String questionId) =>
      _answeredQuestions.contains(questionId);

  // Mark a question as answered
  void markQuestionAsAnswered(String questionId) {
    _answeredQuestions.add(questionId);
    notifyListeners();
  }

  // Reset all answered questions
  void resetAnsweredQuestions() {
    _answeredQuestions.clear();
    notifyListeners();
  }
}
