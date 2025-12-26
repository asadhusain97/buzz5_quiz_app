import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:uuid/uuid.dart';

/// Service for handling Firestore operations for Boards
/// Manages CRUD operations for quiz boards (collections of sets)
class BoardService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  BoardService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Create a new board in Firestore
  ///
  /// Parameters:
  /// - name: Board name
  /// - description: Board description
  /// - setIds: List of set IDs (max 5)
  /// - isDraft: Whether to save as draft (true) or complete (false)
  ///
  /// Returns: The ID of the created board
  Future<String> createBoard({
    required String name,
    required String description,
    required List<String> setIds,
    bool isDraft = true,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('ERROR: No user is currently signed in');
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Creating new board: $name for user ${currentUser.uid}');

      // Validate setIds count
      if (setIds.length > 5) {
        throw Exception('A board can have a maximum of 5 sets');
      }

      // Generate board ID
      final String boardId = _uuid.v4();
      AppLogger.d('Generated board ID: $boardId');

      // Determine status based on isDraft flag
      // Note: BoardModel will enforce that complete status requires 5 sets
      final BoardStatus status =
          isDraft ? BoardStatus.draft : BoardStatus.complete;

      // Create BoardModel
      final boardModel = BoardModel(
        id: boardId,
        name: name,
        description: description,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        setIds: setIds,
        status: status,
      );

      AppLogger.d('BoardModel created with status: ${boardModel.status}');
      AppLogger.d('Board has ${boardModel.setCount} sets');

      // Save to Firestore
      AppLogger.d(
        'Attempting to save to Firestore collection: boards/$boardId',
      );
      try {
        await _firestore
            .collection('boards')
            .doc(boardId)
            .set(boardModel.toJson());
        AppLogger.i('Firestore write successful');
      } catch (firestoreError) {
        AppLogger.e(
          'FIRESTORE WRITE ERROR: $firestoreError',
          error: firestoreError,
        );
        rethrow;
      }

      AppLogger.i(
        'Board created successfully with ID: $boardId, Status: ${boardModel.status}',
      );

      return boardId;
    } catch (e, stackTrace) {
      AppLogger.e('Error creating board: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update an existing board
  ///
  /// Parameters:
  /// - boardId: The ID of the board to update
  /// - name, description: Updated board metadata
  /// - setIds: Updated list of set IDs
  /// - isDraft: Whether to save as draft (true) or complete (false)
  ///
  /// Returns: void
  Future<void> updateBoard({
    required String boardId,
    required String name,
    required String description,
    required List<String> setIds,
    bool isDraft = true,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Updating board: $boardId');

      // Validate setIds count
      if (setIds.length > 5) {
        throw Exception('A board can have a maximum of 5 sets');
      }

      // Get existing board to check ownership
      final DocumentSnapshot doc =
          await _firestore.collection('boards').doc(boardId).get();

      if (!doc.exists) {
        throw Exception('Board not found');
      }

      final boardData = doc.data() as Map<String, dynamic>;
      if (boardData['authorId'] != currentUser.uid) {
        throw Exception('You do not have permission to update this board');
      }

      // Determine status based on isDraft flag
      final BoardStatus status =
          isDraft ? BoardStatus.draft : BoardStatus.complete;

      // Create updated BoardModel
      final boardModel = BoardModel(
        id: boardId,
        name: name,
        description: description,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        setIds: setIds,
        creationDate: DateTime.parse(boardData['creationDate'] as String),
        status: status,
      );

      // Update in Firestore
      await _firestore
          .collection('boards')
          .doc(boardId)
          .update(boardModel.toJson());

      AppLogger.i('Board updated successfully: $boardId');
    } catch (e, stackTrace) {
      AppLogger.e('Error updating board: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get a board by ID
  ///
  /// Parameters:
  /// - boardId: The ID of the board to retrieve
  ///
  /// Returns: BoardModel object
  Future<BoardModel?> getBoard(String boardId) async {
    try {
      AppLogger.i('Fetching board: $boardId');

      final DocumentSnapshot doc =
          await _firestore.collection('boards').doc(boardId).get();

      if (!doc.exists) {
        AppLogger.w('Board not found: $boardId');
        return null;
      }

      final boardModel = BoardModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );
      AppLogger.i('Board fetched successfully: $boardId');

      return boardModel;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching board: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all boards for the current user
  ///
  /// Returns: List of BoardModel objects
  Future<List<BoardModel>> getUserBoards() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Fetching boards for user: ${currentUser.uid}');

      final QuerySnapshot snapshot =
          await _firestore
              .collection('boards')
              .where('authorId', isEqualTo: currentUser.uid)
              .orderBy('creationDate', descending: true)
              .get();

      final List<BoardModel> boards =
          snapshot.docs
              .map(
                (doc) =>
                    BoardModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();

      AppLogger.i('Fetched ${boards.length} boards for user');

      return boards;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error fetching user boards: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if a board with the given name already exists for the current user
  ///
  /// Parameters:
  /// - name: The name to check
  /// - excludeBoardId: Optional board ID to exclude from the check (for edit scenarios)
  ///
  /// Returns: true if a board with this name exists, false otherwise
  Future<bool> checkBoardNameExists(
    String name, {
    String? excludeBoardId,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Checking if board name exists: $name');

      final QuerySnapshot snapshot =
          await _firestore
              .collection('boards')
              .where('authorId', isEqualTo: currentUser.uid)
              .where('name', isEqualTo: name)
              .get();

      // Filter out the excluded board if provided
      final matchingBoards =
          snapshot.docs.where((doc) {
            return excludeBoardId == null || doc.id != excludeBoardId;
          }).toList();

      final exists = matchingBoards.isNotEmpty;
      AppLogger.i('Board name "$name" exists: $exists');

      return exists;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error checking board name: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a board
  ///
  /// Parameters:
  /// - boardId: The ID of the board to delete
  ///
  /// Returns: void
  Future<void> deleteBoard(String boardId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Deleting board: $boardId');

      // Get board to verify ownership
      final DocumentSnapshot doc =
          await _firestore.collection('boards').doc(boardId).get();

      if (!doc.exists) {
        throw Exception('Board not found');
      }

      final boardData = doc.data() as Map<String, dynamic>;
      if (boardData['authorId'] != currentUser.uid) {
        throw Exception('You do not have permission to delete this board');
      }

      // Delete board document
      await _firestore.collection('boards').doc(boardId).delete();

      AppLogger.i('Board deleted successfully: $boardId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting board: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Duplicate an existing board
  ///
  /// Creates a copy of the specified board with a unique name.
  ///
  /// Parameters:
  /// - boardId: The ID of the board to duplicate
  ///
  /// Returns: The ID of the newly created duplicate board
  Future<String> duplicateBoard(String boardId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      AppLogger.i('Duplicating board: $boardId');

      // Get the original board
      final BoardModel? originalBoard = await getBoard(boardId);
      if (originalBoard == null) {
        throw Exception('Board not found: $boardId');
      }

      // Verify ownership
      if (originalBoard.authorId != currentUser.uid) {
        throw Exception('You do not have permission to duplicate this board');
      }

      // Generate a unique name
      String uniqueName = '${originalBoard.name} (Copy)';
      int copyNumber = 2;
      while (await checkBoardNameExists(uniqueName)) {
        uniqueName = '${originalBoard.name} (Copy $copyNumber)';
        copyNumber++;
        if (copyNumber > 100) {
          uniqueName =
              '${originalBoard.name} (Copy ${DateTime.now().millisecondsSinceEpoch})';
          break;
        }
      }

      // Generate new ID for the board
      final String newBoardId = _uuid.v4();

      // Create the duplicated board (always as draft)
      final duplicatedBoard = BoardModel(
        id: newBoardId,
        name: uniqueName,
        description: originalBoard.description,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        setIds: List<String>.from(originalBoard.setIds),
        status: BoardStatus.draft, // Duplicates always start as draft
      );

      // Save to Firestore
      await _firestore
          .collection('boards')
          .doc(newBoardId)
          .set(duplicatedBoard.toJson());

      AppLogger.i(
        'Board duplicated successfully. Original: $boardId, New: $newBoardId',
      );

      return newBoardId;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error duplicating board: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
