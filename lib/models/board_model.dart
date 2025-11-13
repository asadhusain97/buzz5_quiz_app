import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';

/// A class representing a Board, which is a collection of Sets.
class BoardModel {
  final String id;
  final String name;
  final String description;
  final String authorName;
  final String authorId;
  final DateTime creationDate;
  final DateTime modifiedDate;
  final double rating;
  final int downloads;
  final double? price;

  final List<SetModel> sets;

  BoardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.authorName,
    required this.authorId,
    DateTime? creationDate,
    DateTime? modifiedDate,
    this.rating = 0.0,
    this.downloads = 0,
    this.price,
    this.sets = const [],
  }) : creationDate = creationDate ?? DateTime.now(),
       modifiedDate = modifiedDate ?? DateTime.now(),
       assert(sets.length <= 5, 'A board can have a maximum of 5 sets.');

  /// Dynamic getter for the status.
  /// A board is complete only if it has exactly 5 sets and all are complete.
  BoardStatus get status {
    if (sets.length == 5 && sets.every((s) => s.status == SetStatus.complete)) {
      return BoardStatus.complete;
    }
    return BoardStatus.draft;
  }

  /// Dynamic getter for the average difficulty of the board.
  DifficultyLevel get difficulty {
    if (sets.isEmpty) {
      return DifficultyLevel.medium; // Default if no sets
    }
    final totalDifficulty = sets.fold<int>(
      0,
      (prev, set) => prev + set.difficulty!.index,
    );
    final avgDifficultyIndex = (totalDifficulty / sets.length).round();

    if (avgDifficultyIndex >= DifficultyLevel.values.length) {
      return DifficultyLevel.hard;
    }
    return DifficultyLevel.values[avgDifficultyIndex];
  }

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
      rating: json['rating'] as double? ?? 0.0,
      downloads: json['downloads'] as int? ?? 0,
      price: json['price'] as double?,
      sets:
          (json['sets'] as List<dynamic>? ?? [])
              .map((s) => SetModel.fromJson(s as Map<String, dynamic>))
              .toList(),
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
      'rating': rating,
      'downloads': downloads,
      'price': price,
      'status': status.toString(),
      'difficulty': difficulty.toString(),
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}
