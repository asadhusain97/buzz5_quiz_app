import 'package:buzz5_quiz_app/models/question_model.dart';

/// Enums for consistent data
enum SetStatus { draft, complete }

enum DifficultyLevel { easy, medium, hard }

enum QuestionStatus { draft, published }

enum PredefinedTags {
  architecture,
  arts,
  astronomy,
  biology,
  business,
  civics,
  words,
  entertainment,
  fashion,
  foodAndDrinks,
  general,
  geography,
  history,
  india,
  literature,
  logos,
  maths,
  movies,
  mythology,
  other,
  personal,
  politics,
  popCulture,
  science,
  songs,
  sports,
  technology,
  us,
  videoGames,
  wordplay,
  world,
}

/// A class representing a Set of questions.
class SetModel {
  final String id;
  final String name;
  final String description;
  final String? exQuestion;
  final String? exAnswer;
  final String authorId;
  final String authorName;
  final List<PredefinedTags> tags;
  final DateTime creationDate;

  // New fields for marketplace and stats
  final double? price;
  final int downloads;
  final double rating;
  final DifficultyLevel? difficulty;

  // The list of questions
  final List<Question> questions;

  SetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.authorName,
    this.exQuestion,
    this.exAnswer,
    this.tags = const [],
    DateTime? creationDate,
    this.price,
    this.downloads = 0,
    this.rating = 0.0,
    this.difficulty,
    this.questions = const [],
  }) : creationDate = creationDate ?? DateTime.now(),
       assert(
         questions.length <= 5,
         'A set can have a maximum of 5 questions.',
       );

  /// Dynamic getter for the status.
  /// A set is complete only if it has exactly 5 questions and all are published.
  SetStatus get status {
    // A set must have exactly 5 questions to be considered complete.
    if (questions.length != 5) {
      return SetStatus.draft;
    }

    // Additionally, every question within the set must be 'published'.
    for (final question in questions) {
      if (question.status != QuestionStatus.published) {
        return SetStatus.draft;
      }
    }

    // If all checks pass, the set is complete.
    return SetStatus.complete;
  }

  // Get number of questions
  int get questionCount => questions.length;

  // Factory constructor to create a SetModel from a JSON object
  factory SetModel.fromJson(Map<String, dynamic> json) {
    return SetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      tags: List<PredefinedTags>.from(json['tags'] ?? []),
      creationDate: DateTime.parse(json['creationDate'] as String),
      price: json['price'] as double?,
      downloads: json['downloads'] as int? ?? 0,
      rating: json['rating'] as double? ?? 0.0,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      questions:
          (json['questions'] as List<dynamic>? ?? [])
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList(),
    );
  }

  // Method to convert a SetModel object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'authorName': authorName,
      'tags': tags,
      'status': status.toString(),
      'creationDate': creationDate.toIso8601String(),
      'price': price,
      'downloads': downloads,
      'rating': rating,
      'difficulty': difficulty.toString(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
