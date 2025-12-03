import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/models/question_model.dart';
import 'package:buzz5_quiz_app/models/media_model.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for handling Firestore operations for Sets
/// Manages CRUD operations and integrates with StorageService for media uploads
class SetService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  SetService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storageService = storageService ?? StorageService();

  /// Create a new set in Firestore
  ///
  /// Parameters:
  /// - name: Set name
  /// - description: Set description
  /// - tags: List of selected tags
  /// - difficulty: Selected difficulty level
  /// - questionData: List of maps containing question text, answer text, media files, hints, and fundas
  /// - isDraft: Whether this is a draft or complete set
  ///
  /// Returns: The ID of the created set
  Future<String> createSet({
    required String name,
    required String description,
    required List<PredefinedTags> tags,
    required DifficultyLevel? difficulty,
    required List<Map<String, dynamic>> questionData,
    required bool isDraft,
  }) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('ERROR: No user is currently signed in');
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Creating new set: $name for user ${currentUser.uid}');
      AppLogger.d('User email: ${currentUser.email}');
      AppLogger.d('User displayName: ${currentUser.displayName}');
      AppLogger.d('Auth token available: ${await currentUser.getIdToken() != null}');

      // Generate set ID
      final String setId = _uuid.v4();
      AppLogger.d('Generated set ID: $setId');

      // Process questions and upload media
      final List<Question> questions = [];

      for (int i = 0; i < questionData.length; i++) {
        final questionMap = questionData[i];
        final questionId = _uuid.v4();

        AppLogger.d('Processing question ${i + 1} with ID: $questionId');

        // Upload question media if present
        Media? questionMedia;
        if (questionMap['questionMediaFile'] != null) {
          AppLogger.i('Uploading question media for question ${i + 1}');
          questionMedia = await _storageService.uploadMedia(
            file: questionMap['questionMediaFile'] as PlatformFile,
            userId: currentUser.uid,
            setId: setId,
            questionId: questionId,
            mediaType: 'question',
          );
          AppLogger.i('Question media uploaded successfully');
        } else if (questionMap['questionMediaUrl'] != null &&
            questionMap['questionMediaUrl'].toString().trim().isNotEmpty) {
          // If URL is provided instead of file, create a simple Media object
          // This is for cases where media is already hosted elsewhere
          questionMedia = Media(
            type: 'image', // Default to image, can be improved
            storagePath: '', // No storage path for external URLs
            downloadURL: questionMap['questionMediaUrl'] as String,
            fileSize: 0,
            status: 'ready',
          );
        }

        // Upload answer media if present
        Media? answerMedia;
        if (questionMap['answerMediaFile'] != null) {
          AppLogger.i('Uploading answer media for question ${i + 1}');
          answerMedia = await _storageService.uploadMedia(
            file: questionMap['answerMediaFile'] as PlatformFile,
            userId: currentUser.uid,
            setId: setId,
            questionId: questionId,
            mediaType: 'answer',
          );
          AppLogger.i('Answer media uploaded successfully');
        } else if (questionMap['answerMediaUrl'] != null &&
            questionMap['answerMediaUrl'].toString().trim().isNotEmpty) {
          answerMedia = Media(
            type: 'image',
            storagePath: '',
            downloadURL: questionMap['answerMediaUrl'] as String,
            fileSize: 0,
            status: 'ready',
          );
        }

        // Create Question object
        final question = Question(
          id: questionId,
          questionText: questionMap['questionText'] as String?,
          questionMedia: questionMedia,
          answerText: questionMap['answerText'] as String?,
          answerMedia: answerMedia,
          points: questionMap['points'] as int? ?? 10,
          hint: questionMap['hint'] as String?,
          funda: questionMap['funda'] as String?,
        );

        questions.add(question);
        AppLogger.d('Question ${i + 1} processed successfully');
      }

      // Create SetModel
      final setModel = SetModel(
        id: setId,
        name: name,
        description: description,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        tags: tags,
        difficulty: difficulty,
        isPrivate: true, // Always private as per requirement (drafts are private)
        questions: questions,
      );

      AppLogger.d('SetModel created with status: ${setModel.status}');

      // Save to Firestore
      AppLogger.d('Attempting to save to Firestore collection: sets/$setId');
      try {
        await _firestore.collection('sets').doc(setId).set(setModel.toJson());
        AppLogger.i('Firestore write successful');
      } catch (firestoreError) {
        AppLogger.e(
          'FIRESTORE WRITE ERROR: $firestoreError',
          error: firestoreError,
        );
        AppLogger.e('This is likely a permissions issue. Check Firestore rules.');
        rethrow;
      }

      AppLogger.i(
        'Set created successfully with ID: $setId, Status: ${setModel.status}',
      );

      return setId;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error creating set: $e',
        error: e,
        stackTrace: stackTrace,
      );

      // Provide helpful error messages
      if (e.toString().contains('permission-denied')) {
        AppLogger.e(
          'PERMISSION DENIED: Firestore security rules are blocking this write.',
        );
        AppLogger.e('Make sure you have deployed firestore.rules');
      } else if (e.toString().contains('unauthenticated')) {
        AppLogger.e('USER NOT AUTHENTICATED: User must be signed in');
      }

      rethrow;
    }
  }

  /// Update an existing set
  ///
  /// Parameters:
  /// - setId: The ID of the set to update
  /// - name, description, tags, difficulty: Updated set metadata
  /// - questionData: Updated question data
  ///
  /// Returns: void
  Future<void> updateSet({
    required String setId,
    required String name,
    required String description,
    required List<PredefinedTags> tags,
    required DifficultyLevel? difficulty,
    required List<Map<String, dynamic>> questionData,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Updating set: $setId');

      // Get existing set to check ownership
      final DocumentSnapshot doc =
          await _firestore.collection('sets').doc(setId).get();

      if (!doc.exists) {
        throw Exception('Set not found');
      }

      final setData = doc.data() as Map<String, dynamic>;
      if (setData['authorId'] != currentUser.uid) {
        throw Exception('You do not have permission to update this set');
      }

      // Process questions similar to createSet
      final List<Question> questions = [];

      for (int i = 0; i < questionData.length; i++) {
        final questionMap = questionData[i];
        final questionId = questionMap['id'] as String? ?? _uuid.v4();

        // Upload media if files are provided
        Media? questionMedia;
        if (questionMap['questionMediaFile'] != null) {
          questionMedia = await _storageService.uploadMedia(
            file: questionMap['questionMediaFile'] as PlatformFile,
            userId: currentUser.uid,
            setId: setId,
            questionId: questionId,
            mediaType: 'question',
          );
        } else if (questionMap['questionMedia'] != null) {
          // Keep existing media
          questionMedia = questionMap['questionMedia'] as Media;
        } else if (questionMap['questionMediaUrl'] != null &&
            questionMap['questionMediaUrl'].toString().trim().isNotEmpty) {
          questionMedia = Media(
            type: 'image',
            storagePath: '',
            downloadURL: questionMap['questionMediaUrl'] as String,
            fileSize: 0,
            status: 'ready',
          );
        }

        Media? answerMedia;
        if (questionMap['answerMediaFile'] != null) {
          answerMedia = await _storageService.uploadMedia(
            file: questionMap['answerMediaFile'] as PlatformFile,
            userId: currentUser.uid,
            setId: setId,
            questionId: questionId,
            mediaType: 'answer',
          );
        } else if (questionMap['answerMedia'] != null) {
          answerMedia = questionMap['answerMedia'] as Media;
        } else if (questionMap['answerMediaUrl'] != null &&
            questionMap['answerMediaUrl'].toString().trim().isNotEmpty) {
          answerMedia = Media(
            type: 'image',
            storagePath: '',
            downloadURL: questionMap['answerMediaUrl'] as String,
            fileSize: 0,
            status: 'ready',
          );
        }

        final question = Question(
          id: questionId,
          questionText: questionMap['questionText'] as String?,
          questionMedia: questionMedia,
          answerText: questionMap['answerText'] as String?,
          answerMedia: answerMedia,
          points: questionMap['points'] as int? ?? 10,
          hint: questionMap['hint'] as String?,
          funda: questionMap['funda'] as String?,
        );

        questions.add(question);
      }

      // Create updated SetModel
      final setModel = SetModel(
        id: setId,
        name: name,
        description: description,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        tags: tags,
        difficulty: difficulty,
        isPrivate: true, // Always private
        questions: questions,
        creationDate: DateTime.parse(setData['creationDate'] as String),
      );

      // Update in Firestore
      await _firestore.collection('sets').doc(setId).update(setModel.toJson());

      AppLogger.i('Set updated successfully: $setId');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating set: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get a set by ID
  ///
  /// Parameters:
  /// - setId: The ID of the set to retrieve
  ///
  /// Returns: SetModel object
  Future<SetModel?> getSet(String setId) async {
    try {
      AppLogger.i('Fetching set: $setId');

      final DocumentSnapshot doc =
          await _firestore.collection('sets').doc(setId).get();

      if (!doc.exists) {
        AppLogger.w('Set not found: $setId');
        return null;
      }

      final setModel = SetModel.fromJson(doc.data() as Map<String, dynamic>);
      AppLogger.i('Set fetched successfully: $setId');

      return setModel;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching set: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all sets for the current user
  ///
  /// Returns: List of SetModel objects
  Future<List<SetModel>> getUserSets() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Fetching sets for user: ${currentUser.uid}');

      final QuerySnapshot snapshot = await _firestore
          .collection('sets')
          .where('authorId', isEqualTo: currentUser.uid)
          .orderBy('creationDate', descending: true)
          .get();

      final List<SetModel> sets = snapshot.docs
          .map((doc) => SetModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      AppLogger.i('Fetched ${sets.length} sets for user');

      return sets;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error fetching user sets: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a set
  ///
  /// Parameters:
  /// - setId: The ID of the set to delete
  ///
  /// Returns: void
  Future<void> deleteSet(String setId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Deleting set: $setId');

      // Get set to verify ownership and get media paths
      final DocumentSnapshot doc =
          await _firestore.collection('sets').doc(setId).get();

      if (!doc.exists) {
        throw Exception('Set not found');
      }

      final setData = doc.data() as Map<String, dynamic>;
      if (setData['authorId'] != currentUser.uid) {
        throw Exception('You do not have permission to delete this set');
      }

      // Delete media files
      final SetModel setModel = SetModel.fromJson(setData);
      for (final question in setModel.questions) {
        if (question.questionMedia != null &&
            question.questionMedia!.storagePath.isNotEmpty) {
          await _storageService.deleteMedia(
            question.questionMedia!.storagePath,
          );
        }
        if (question.answerMedia != null &&
            question.answerMedia!.storagePath.isNotEmpty) {
          await _storageService.deleteMedia(question.answerMedia!.storagePath);
        }
      }

      // Delete set document
      await _firestore.collection('sets').doc(setId).delete();

      AppLogger.i('Set deleted successfully: $setId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting set: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
