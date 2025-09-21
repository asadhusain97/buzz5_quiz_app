import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:buzz5_quiz_app/models/question.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class QuestionService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String questionsCollection = 'questions';

  QuestionService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Create a new question
  Future<String?> createQuestion(Question question) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(question.questionId)
          .set(question.toJson());

      AppLogger.i('Question created successfully: ${question.questionId}');
      return question.questionId;
    } catch (e) {
      AppLogger.e('Error creating question: $e');
      return null;
    }
  }

  // Update an existing question
  Future<bool> updateQuestion(Question question) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(question.questionId)
          .update(question.copyWith(updatedAt: DateTime.now()).toJson());

      AppLogger.i('Question updated successfully: ${question.questionId}');
      return true;
    } catch (e) {
      AppLogger.e('Error updating question: $e');
      return false;
    }
  }

  // Get a single question by ID
  Future<Question?> getQuestion(String questionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(questionsCollection)
          .doc(questionId)
          .get();

      if (doc.exists) {
        return Question.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        AppLogger.w('Question not found: $questionId');
        return null;
      }
    } catch (e) {
      AppLogger.e('Error fetching question: $e');
      return null;
    }
  }

  // Get all questions by user
  Future<List<Question>> getQuestionsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(questionsCollection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching questions by user: $e');
      return [];
    }
  }

  // Get draft questions (isActive = false) by user
  Future<List<Question>> getDraftQuestionsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(questionsCollection)
          .where('createdBy', isEqualTo: userId)
          .where('isActive', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching draft questions: $e');
      return [];
    }
  }

  // Get active questions (isActive = true) by user
  Future<List<Question>> getActiveQuestionsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(questionsCollection)
          .where('createdBy', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching active questions: $e');
      return [];
    }
  }

  // Get questions by category
  Future<List<Question>> getQuestionsByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(questionsCollection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Error fetching questions by category: $e');
      return [];
    }
  }

  // Delete a question
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(questionId)
          .delete();

      AppLogger.i('Question deleted successfully: $questionId');
      return true;
    } catch (e) {
      AppLogger.e('Error deleting question: $e');
      return false;
    }
  }

  // Upload media file to Firebase Storage
  Future<String?> uploadMedia(File file, String questionId, {bool isAnswer = false}) async {
    try {
      // Validate file size (15MB = 15 * 1024 * 1024 bytes)
      const maxSizeInBytes = 15 * 1024 * 1024;
      if (await file.length() > maxSizeInBytes) {
        AppLogger.e('File size exceeds 15MB limit');
        return null;
      }

      // Generate file path
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = file.path.split('.').last;
      final mediaType = isAnswer ? 'answer' : 'question';
      final filePath = 'questions/$questionId/$mediaType/$fileName.$fileExtension';

      // Upload file
      final reference = _storage.ref().child(filePath);
      final uploadTask = await reference.putFile(file);

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await reference.getDownloadURL();
        AppLogger.i('Media uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        AppLogger.e('Upload failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e) {
      AppLogger.e('Error uploading media: $e');
      return null;
    }
  }

  // Upload media from URL (copy from external source to Firebase Storage)
  Future<String?> uploadMediaFromUrl(String url, String questionId, {bool isAnswer = false}) async {
    try {
      // For now, we'll just return the URL as-is
      // In a production app, you might want to download and re-upload to your own storage
      // for better control and to avoid broken links
      AppLogger.i('Media URL set: $url');
      return url;
    } catch (e) {
      AppLogger.e('Error handling media URL: $e');
      return null;
    }
  }

  // Delete media file from Firebase Storage
  Future<bool> deleteMedia(String mediaUrl) async {
    try {
      if (mediaUrl.isEmpty || !mediaUrl.contains('firebase')) {
        return true; // External URLs don't need deletion
      }

      final reference = _storage.refFromURL(mediaUrl);
      await reference.delete();
      AppLogger.i('Media deleted successfully: $mediaUrl');
      return true;
    } catch (e) {
      AppLogger.e('Error deleting media: $e');
      return false;
    }
  }

  // Stream of draft questions for real-time updates
  Stream<List<Question>> streamDraftQuestionsByUser(String userId) {
    return _firestore
        .collection(questionsCollection)
        .where('createdBy', isEqualTo: userId)
        .where('isActive', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Question.fromJson(doc.data()))
            .toList());
  }

  // Stream of active questions for real-time updates
  Stream<List<Question>> streamActiveQuestionsByUser(String userId) {
    return _firestore
        .collection(questionsCollection)
        .where('createdBy', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Question.fromJson(doc.data()))
            .toList());
  }

  // Activate a draft question (set isActive to true)
  Future<bool> activateQuestion(String questionId) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(questionId)
          .update({
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.i('Question activated: $questionId');
      return true;
    } catch (e) {
      AppLogger.e('Error activating question: $e');
      return false;
    }
  }

  // Deactivate a question (set isActive to false)
  Future<bool> deactivateQuestion(String questionId) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(questionId)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.i('Question deactivated: $questionId');
      return true;
    } catch (e) {
      AppLogger.e('Error deactivating question: $e');
      return false;
    }
  }
}