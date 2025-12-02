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

  BoardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.authorName,
    required this.authorId,
    DateTime? creationDate,
    DateTime? modifiedDate,
    this.setIds = const [],
  }) : creationDate = creationDate ?? DateTime.now(),
       modifiedDate = modifiedDate ?? DateTime.now(),
       assert(setIds.length <= 5, 'A board can have a maximum of 5 sets.');

  /// Dynamic getter for the status.
  /// A board is complete only if it has exactly 5 sets.
  BoardStatus get status {
    if (setIds.length == 5) {
      return BoardStatus.complete;
    }
    return BoardStatus.draft;
  }

  /// Get the number of sets in this board.
  int get setCount => setIds.length;

  // Factory constructor to create a BoardModel from a JSON object
  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      authorName: json['authorName'] as String,
      authorId: json['authorId'] as String,
      creationDate: DateTime.parse(json['creationDate'] as String),
      modifiedDate: DateTime.parse(json['modifiedDate'] as String),
      setIds: List<String>.from(json['setIds'] as List<dynamic>? ?? []),
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
