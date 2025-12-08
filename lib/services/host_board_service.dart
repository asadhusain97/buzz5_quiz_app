import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/models/qrow.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/services/board_service.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';

/// Service for fetching boards from Firebase for hosting quiz games.
///
/// This service acts as an adapter between the Firebase data structure
/// (BoardModel -> SetModel -> Question) and the QRow format expected by
/// the QuestionBoardPage.
///
/// Key responsibilities:
/// - Fetch user's complete boards from Firebase
/// - Fetch all sets referenced by each board
/// - Transform the hierarchical Firebase data into flat QRow list
class HostBoardService {
  final BoardService _boardService;
  final SetService _setService;

  HostBoardService({
    BoardService? boardService,
    SetService? setService,
  })  : _boardService = boardService ?? BoardService(),
        _setService = setService ?? SetService();

  /// Fetches all hostable boards for the current user and transforms them
  /// into the QRow format expected by QuestionBoardPage.
  ///
  /// Only boards with status == complete (5 sets) are included.
  ///
  /// Returns: List of QRow objects representing all questions across all
  /// hostable boards, with board name as 'round' and set name as 'setName'.
  Future<List<QRow>> fetchHostableBoardsAsQRows() async {
    try {
      AppLogger.i('Fetching hostable boards from Firebase');

      // 1. Get all user's boards
      final List<BoardModel> allBoards = await _boardService.getUserBoards();
      AppLogger.d('Found ${allBoards.length} total boards for user');

      // 2. Filter to only complete boards
      final List<BoardModel> completeBoards = allBoards
          .where((board) => board.status == BoardStatus.complete)
          .toList();
      AppLogger.i('Found ${completeBoards.length} complete boards');

      if (completeBoards.isEmpty) {
        AppLogger.w('No complete boards found for user');
        return [];
      }

      // 3. Transform each board into QRows
      final List<QRow> allQRows = [];
      int globalQid = 1; // Global question ID counter

      for (final board in completeBoards) {
        AppLogger.d('Processing board: ${board.name} with ${board.setIds.length} sets');

        // Fetch all sets for this board
        final List<SetModel> sets = await _fetchSetsForBoard(board.setIds);

        // Transform each set's questions into QRows
        for (final set in sets) {
          for (final question in set.questions) {
            final qrow = QRow.fromFirebase(
              qid: globalQid++,
              boardName: board.name,
              setModel: set,
              questionText: question.questionText,
              questionMediaUrl: question.questionMedia?.downloadURL,
              answerText: question.answerText,
              answerMediaUrl: question.answerMedia?.downloadURL,
              points: question.points,
            );
            allQRows.add(qrow);
          }
        }
      }

      AppLogger.i('Successfully transformed ${allQRows.length} questions from ${completeBoards.length} boards');
      return allQRows;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching hostable boards: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches all sets for a given list of set IDs.
  ///
  /// Parameters:
  /// - setIds: List of set IDs to fetch
  ///
  /// Returns: List of SetModel objects (only non-null results)
  Future<List<SetModel>> _fetchSetsForBoard(List<String> setIds) async {
    final List<SetModel> sets = [];

    for (final setId in setIds) {
      try {
        final set = await _setService.getSet(setId);
        if (set != null) {
          sets.add(set);
          AppLogger.d('Fetched set: ${set.name} with ${set.questions.length} questions');
        } else {
          AppLogger.w('Set not found: $setId');
        }
      } catch (e) {
        AppLogger.e('Error fetching set $setId: $e');
        // Continue with other sets even if one fails
      }
    }

    return sets;
  }

  /// Gets list of unique board names available for hosting.
  ///
  /// This is useful for populating dropdowns without fetching all question data.
  ///
  /// Returns: List of board names (only complete boards)
  Future<List<String>> getHostableBoardNames() async {
    try {
      final List<BoardModel> allBoards = await _boardService.getUserBoards();
      final List<String> boardNames = allBoards
          .where((board) => board.status == BoardStatus.complete)
          .map((board) => board.name)
          .toList();

      AppLogger.i('Found ${boardNames.length} hostable board names');
      return boardNames;
    } catch (e, stackTrace) {
      AppLogger.e('Error getting hostable board names: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
