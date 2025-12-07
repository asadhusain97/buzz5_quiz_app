import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/models/question_model.dart';
import 'package:buzz5_quiz_app/models/media_model.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart' hide QuestionStatus;
import 'package:buzz5_quiz_app/services/storage_service.dart';
import 'package:buzz5_quiz_app/services/import_service.dart';
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
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
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
      AppLogger.d(
        'Auth token available: ${await currentUser.getIdToken() != null}',
      );

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
        isPrivate:
            true, // Always private as per requirement (drafts are private)
        questions: questions,
      );

      AppLogger.d('SetModel created with status: ${setModel.status}');
      AppLogger.d('Set has ${setModel.questions.length} questions');

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
        AppLogger.e(
          'This is likely a permissions issue. Check Firestore rules.',
        );
        rethrow;
      }

      AppLogger.i(
        'Set created successfully with ID: $setId, Status: ${setModel.status}',
      );

      return setId;
    } catch (e, stackTrace) {
      AppLogger.e('Error creating set: $e', error: e, stackTrace: stackTrace);

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

      final QuerySnapshot snapshot =
          await _firestore
              .collection('sets')
              .where('authorId', isEqualTo: currentUser.uid)
              .orderBy('creationDate', descending: true)
              .get();

      final List<SetModel> sets =
          snapshot.docs
              .map(
                (doc) => SetModel.fromJson(doc.data() as Map<String, dynamic>),
              )
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

  /// Check if a set with the given name already exists for the current user
  ///
  /// Parameters:
  /// - name: The name to check
  /// - excludeSetId: Optional set ID to exclude from the check (for edit scenarios)
  ///
  /// Returns: true if a set with this name exists, false otherwise
  Future<bool> checkSetNameExists(String name, {String? excludeSetId}) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Checking if set name exists: $name');

      final QuerySnapshot snapshot =
          await _firestore
              .collection('sets')
              .where('authorId', isEqualTo: currentUser.uid)
              .where('name', isEqualTo: name)
              .get();

      // Filter out the excluded set if provided
      final matchingSets =
          snapshot.docs.where((doc) {
            return excludeSetId == null || doc.id != excludeSetId;
          }).toList();

      final exists = matchingSets.isNotEmpty;
      AppLogger.i('Set name "$name" exists: $exists');

      return exists;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error checking set name: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate a unique name by appending a suffix like " (Copy)", " (Copy 2)", etc.
  ///
  /// Parameters:
  /// - baseName: The base name to use
  ///
  /// Returns: A unique name that doesn't conflict with existing sets
  Future<String> generateUniqueName(String baseName) async {
    try {
      AppLogger.i('Generating unique name for: $baseName');

      // First, try the base name
      if (!await checkSetNameExists(baseName)) {
        return baseName;
      }

      // Try with " (Copy)" suffix
      String candidateName = '$baseName (Copy)';
      if (!await checkSetNameExists(candidateName)) {
        return candidateName;
      }

      // Try with " (Copy N)" suffix, incrementing N
      int copyNumber = 2;
      while (copyNumber < 100) {
        // Safety limit
        candidateName = '$baseName (Copy $copyNumber)';
        if (!await checkSetNameExists(candidateName)) {
          AppLogger.i('Generated unique name: $candidateName');
          return candidateName;
        }
        copyNumber++;
      }

      // Fallback: append timestamp if we somehow hit the limit
      candidateName =
          '$baseName (Copy ${DateTime.now().millisecondsSinceEpoch})';
      AppLogger.w('Using timestamp-based name: $candidateName');
      return candidateName;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error generating unique name: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Duplicate an existing set
  ///
  /// Creates a copy of the specified set with a unique name.
  /// The duplicate will have:
  /// - A new ID
  /// - A unique name (original name with " (Copy)" suffix)
  /// - New creation date
  /// - Reset downloads (0) and rating (0.0)
  /// - Same questions, tags, difficulty, and other metadata
  /// - References to the same media files (not copied)
  ///
  /// Parameters:
  /// - setId: The ID of the set to duplicate
  ///
  /// Returns: The ID of the newly created duplicate set
  Future<String> duplicateSet(String setId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Duplicating set: $setId');

      // Get the original set
      final SetModel? originalSet = await getSet(setId);
      if (originalSet == null) {
        throw Exception('Set not found: $setId');
      }

      // Verify ownership
      if (originalSet.authorId != currentUser.uid) {
        throw Exception('You do not have permission to duplicate this set');
      }

      // Generate a unique name
      final String uniqueName = await generateUniqueName(originalSet.name);
      AppLogger.i('Using unique name: $uniqueName');

      // Generate new IDs for the set and questions
      final String newSetId = _uuid.v4();
      final List<Question> newQuestions = [];

      for (final question in originalSet.questions) {
        // Create new question with new ID but same content
        // Media references are kept the same (not copied)
        final newQuestion = Question(
          id: _uuid.v4(),
          questionText: question.questionText,
          questionMedia: question.questionMedia,
          answerText: question.answerText,
          answerMedia: question.answerMedia,
          points: question.points,
          hint: question.hint,
          funda: question.funda,
        );
        newQuestions.add(newQuestion);
      }

      // Create the duplicated set
      final duplicatedSet = SetModel(
        id: newSetId,
        name: uniqueName,
        description: originalSet.description,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        tags: originalSet.tags,
        difficulty: originalSet.difficulty,
        isPrivate: originalSet.isPrivate,
        questions: newQuestions,
        downloads: 0, // Reset downloads
        rating: 0.0, // Reset rating
        price: originalSet.price,
      );

      // Save to Firestore
      await _firestore
          .collection('sets')
          .doc(newSetId)
          .set(duplicatedSet.toJson());

      AppLogger.i(
        'Set duplicated successfully. Original: $setId, New: $newSetId',
      );

      return newSetId;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error duplicating set: $e',
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

  /// Bulk import sets from parsed data
  ///
  /// Parameters:
  /// - parsedSets: List of ParsedSet objects to import
  ///
  /// Returns: List of created set IDs
  Future<List<String>> importSets(List<ParsedSet> parsedSets) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Starting bulk import of ${parsedSets.length} sets');
      final List<String> createdSetIds = [];

      // Track valid operations in batch (max 500 per batch in Firestore)
      // Since we are doing read-then-write for unique names, we can't fully batch everything strictly.
      // But we can batch the final writes.
      //
      // Actually, for simplicity and to handle the async unique name check,
      // we'll process one by one but could optimized to execute in parallel.
      // Given typical import size (small), sequential is safer and simpler for now to prevent name collisions.

      for (final parsedSet in parsedSets) {
        // 1. Generate unique name
        final String uniqueName = await generateUniqueName(parsedSet.name);

        // 2. Generate IDs
        final String setId = _uuid.v4();

        // 3. Create Questions
        final List<Question> questions = [];
        for (final pQuestion in parsedSet.questions) {
          final String questionId = _uuid.v4();

          // Handle Media URLs
          Media? qMedia;
          if (pQuestion.questionMediaUrl != null) {
            qMedia = Media(
              type: 'image',
              storagePath: '',
              downloadURL: pQuestion.questionMediaUrl!,
              fileSize: 0,
              status: 'ready',
            );
          }

          Media? aMedia;
          if (pQuestion.answerMediaUrl != null) {
            aMedia = Media(
              type: 'image',
              storagePath: '',
              downloadURL: pQuestion.answerMediaUrl!,
              fileSize: 0,
              status: 'ready',
            );
          }

          questions.add(
            Question(
              id: questionId,
              questionText: pQuestion.questionText,
              questionMedia: qMedia,
              answerText: pQuestion.answerText,
              answerMedia: aMedia,
              points: pQuestion.points,
              status: QuestionStatus.complete,
            ),
          );
        }

        // 4. Create SetModel
        final setModel = SetModel(
          id: setId,
          name: uniqueName,
          description: parsedSet.description,
          authorId: currentUser.uid,
          authorName:
              currentUser.displayName ?? currentUser.email ?? 'Imported User',
          tags: [PredefinedTags.general], // Default tag
          difficulty: parsedSet.difficulty,
          isPrivate: true,
          questions: questions,
        );

        // 5. Add to batch (or save directly)
        // Since we did async checks above, let's just save directly to be safe and simple
        await _firestore.collection('sets').doc(setId).set(setModel.toJson());
        createdSetIds.add(setId);
        AppLogger.i('Imported set: $uniqueName ($setId)');
      }

      AppLogger.i(
        'Bulk import completed. Created ${createdSetIds.length} sets.',
      );
      return createdSetIds;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error during bulk import: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
