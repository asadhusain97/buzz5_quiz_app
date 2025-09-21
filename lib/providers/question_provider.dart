import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:buzz5_quiz_app/models/question.dart';
import 'package:buzz5_quiz_app/services/question_service.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class QuestionProvider extends ChangeNotifier {
  final QuestionService _questionService;

  List<Question> _questions = [];
  List<Question> _draftQuestions = [];
  List<Question> _activeQuestions = [];
  Question? _currentQuestion;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Question> get questions => _questions;
  List<Question> get draftQuestions => _draftQuestions;
  List<Question> get activeQuestions => _activeQuestions;
  Question? get currentQuestion => _currentQuestion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  QuestionProvider({QuestionService? questionService})
      : _questionService = questionService ?? QuestionService();

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create a new question
  Future<String?> createQuestion(Question question) async {
    _setLoading(true);
    _setError(null);

    try {
      final questionId = await _questionService.createQuestion(question);
      if (questionId != null) {
        AppLogger.i('Question created successfully: $questionId');
        // Refresh the appropriate list based on question status
        if (question.isActive) {
          await loadActiveQuestionsByUser(question.createdBy);
        } else {
          await loadDraftQuestionsByUser(question.createdBy);
        }
      } else {
        _setError('Failed to create question');
      }
      return questionId;
    } catch (e) {
      AppLogger.e('Error in createQuestion: $e');
      _setError('Error creating question: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing question
  Future<bool> updateQuestion(Question question) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _questionService.updateQuestion(question);
      if (success) {
        AppLogger.i('Question updated successfully: ${question.questionId}');
        // Update local lists
        _updateQuestionInLists(question);
        // Refresh the appropriate list based on question status
        if (question.isActive) {
          await loadActiveQuestionsByUser(question.createdBy);
        } else {
          await loadDraftQuestionsByUser(question.createdBy);
        }
      } else {
        _setError('Failed to update question');
      }
      return success;
    } catch (e) {
      AppLogger.e('Error in updateQuestion: $e');
      _setError('Error updating question: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load a single question by ID
  Future<Question?> loadQuestion(String questionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final question = await _questionService.getQuestion(questionId);
      if (question != null) {
        _currentQuestion = question;
        notifyListeners();
      } else {
        _setError('Question not found');
      }
      return question;
    } catch (e) {
      AppLogger.e('Error in loadQuestion: $e');
      _setError('Error loading question: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Load questions by user
  Future<void> loadQuestionsByUser(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      _questions = await _questionService.getQuestionsByUser(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error in loadQuestionsByUser: $e');
      _setError('Error loading questions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load draft questions by user
  Future<void> loadDraftQuestionsByUser(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      _draftQuestions = await _questionService.getDraftQuestionsByUser(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error in loadDraftQuestionsByUser: $e');
      _setError('Error loading draft questions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load active questions by user
  Future<void> loadActiveQuestionsByUser(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      _activeQuestions = await _questionService.getActiveQuestionsByUser(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error in loadActiveQuestionsByUser: $e');
      _setError('Error loading active questions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a question
  Future<bool> deleteQuestion(String questionId, String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _questionService.deleteQuestion(questionId);
      if (success) {
        // Remove from local lists
        _removeQuestionFromLists(questionId);
        AppLogger.i('Question deleted successfully: $questionId');
      } else {
        _setError('Failed to delete question');
      }
      return success;
    } catch (e) {
      AppLogger.e('Error in deleteQuestion: $e');
      _setError('Error deleting question: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload media file
  Future<String?> uploadMedia(File file, String questionId, {bool isAnswer = false}) async {
    _setLoading(true);
    _setError(null);

    try {
      final mediaUrl = await _questionService.uploadMedia(file, questionId, isAnswer: isAnswer);
      if (mediaUrl == null) {
        _setError('Failed to upload media. Please check file size (max 15MB).');
      }
      return mediaUrl;
    } catch (e) {
      AppLogger.e('Error in uploadMedia: $e');
      _setError('Error uploading media: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Upload media from URL
  Future<String?> uploadMediaFromUrl(String url, String questionId, {bool isAnswer = false}) async {
    _setLoading(true);
    _setError(null);

    try {
      final mediaUrl = await _questionService.uploadMediaFromUrl(url, questionId, isAnswer: isAnswer);
      if (mediaUrl == null) {
        _setError('Failed to process media URL');
      }
      return mediaUrl;
    } catch (e) {
      AppLogger.e('Error in uploadMediaFromUrl: $e');
      _setError('Error processing media URL: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Activate a question
  Future<bool> activateQuestion(String questionId, String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _questionService.activateQuestion(questionId);
      if (success) {
        // Move question from draft to active list
        final question = _draftQuestions.firstWhere((q) => q.questionId == questionId);
        final activatedQuestion = question.copyWith(isActive: true);

        _draftQuestions.removeWhere((q) => q.questionId == questionId);
        _activeQuestions.add(activatedQuestion);
        _updateQuestionInLists(activatedQuestion);

        notifyListeners();
        AppLogger.i('Question activated successfully: $questionId');
      } else {
        _setError('Failed to activate question');
      }
      return success;
    } catch (e) {
      AppLogger.e('Error in activateQuestion: $e');
      _setError('Error activating question: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deactivate a question
  Future<bool> deactivateQuestion(String questionId, String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _questionService.deactivateQuestion(questionId);
      if (success) {
        // Move question from active to draft list
        final question = _activeQuestions.firstWhere((q) => q.questionId == questionId);
        final deactivatedQuestion = question.copyWith(isActive: false);

        _activeQuestions.removeWhere((q) => q.questionId == questionId);
        _draftQuestions.add(deactivatedQuestion);
        _updateQuestionInLists(deactivatedQuestion);

        notifyListeners();
        AppLogger.i('Question deactivated successfully: $questionId');
      } else {
        _setError('Failed to deactivate question');
      }
      return success;
    } catch (e) {
      AppLogger.e('Error in deactivateQuestion: $e');
      _setError('Error deactivating question: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set current question being edited
  void setCurrentQuestion(Question? question) {
    _currentQuestion = question;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _questions.clear();
    _draftQuestions.clear();
    _activeQuestions.clear();
    _currentQuestion = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Helper method to update a question in all relevant lists
  void _updateQuestionInLists(Question updatedQuestion) {
    // Update in main questions list
    final mainIndex = _questions.indexWhere((q) => q.questionId == updatedQuestion.questionId);
    if (mainIndex >= 0) {
      _questions[mainIndex] = updatedQuestion;
    }

    // Update in draft questions list
    final draftIndex = _draftQuestions.indexWhere((q) => q.questionId == updatedQuestion.questionId);
    if (draftIndex >= 0) {
      _draftQuestions[draftIndex] = updatedQuestion;
    }

    // Update in active questions list
    final activeIndex = _activeQuestions.indexWhere((q) => q.questionId == updatedQuestion.questionId);
    if (activeIndex >= 0) {
      _activeQuestions[activeIndex] = updatedQuestion;
    }

    // Update current question if it matches
    if (_currentQuestion?.questionId == updatedQuestion.questionId) {
      _currentQuestion = updatedQuestion;
    }
  }

  // Helper method to remove a question from all lists
  void _removeQuestionFromLists(String questionId) {
    _questions.removeWhere((q) => q.questionId == questionId);
    _draftQuestions.removeWhere((q) => q.questionId == questionId);
    _activeQuestions.removeWhere((q) => q.questionId == questionId);

    if (_currentQuestion?.questionId == questionId) {
      _currentQuestion = null;
    }

    notifyListeners();
  }
}