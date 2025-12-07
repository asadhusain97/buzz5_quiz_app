import 'package:buzz5_quiz_app/models/all_enums.dart';

/// A class representing a Board, which is a collection of Sets.
/// Boards are not for sale - they are DIY collections that users create.
/// A set can be part of multiple boards.
class BoardModel {
  final String id;
  final String name;
  final String description;
  final String authorName;
  final String authorId;
  final DateTime creationDate;
  final DateTime modifiedDate;

  /// List of set IDs that belong to this board.
  /// Storing IDs instead of full objects saves space and allows sets to be in multiple boards.
  final List<String> setIds;

  /// The explicit status of this board.
  /// A board can only be marked as complete if it has exactly 5 sets.
  final BoardStatus _status;

  BoardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.authorName,
    required this.authorId,
    DateTime? creationDate,
    DateTime? modifiedDate,
    this.setIds = const [],
    BoardStatus? status,
  }) : creationDate = creationDate ?? DateTime.now(),
       modifiedDate = modifiedDate ?? DateTime.now(),
       // Status defaults to draft. Can only be complete if 5 sets are present.
       _status = (status == BoardStatus.complete && setIds.length == 5)
           ? BoardStatus.complete
           : BoardStatus.draft,
       assert(setIds.length <= 5, 'A board can have a maximum of 5 sets.');

  /// Get the status of this board.
  /// A board is complete only if it was explicitly saved as complete AND has exactly 5 sets.
  BoardStatus get status => _status;

  /// Get the number of sets in this board.
  int get setCount => setIds.length;

  // Factory constructor to create a BoardModel from a JSON object
  factory BoardModel.fromJson(Map<String, dynamic> json) {
    // Parse status from string (e.g., "BoardStatus.complete" or "BoardStatus.draft")
    BoardStatus? parsedStatus;
    if (json['status'] != null) {
      final statusString = json['status'] as String;
      if (statusString.contains('complete')) {
        parsedStatus = BoardStatus.complete;
      } else {
        parsedStatus = BoardStatus.draft;
      }
    }

    return BoardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      authorName: json['authorName'] as String,
      authorId: json['authorId'] as String,
      creationDate: DateTime.parse(json['creationDate'] as String),
      modifiedDate: DateTime.parse(json['modifiedDate'] as String),
      setIds: List<String>.from(json['setIds'] as List<dynamic>? ?? []),
      status: parsedStatus,
    );
  }

  // Method to convert a BoardModel object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'authorName': authorName,
      'authorId': authorId,
      'creationDate': creationDate.toIso8601String(),
      'modifiedDate': modifiedDate.toIso8601String(),
      'status': status.toString(),
      'setIds': setIds,
    };
  }
}
