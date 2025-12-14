import 'package:buzz5_quiz_app/models/all_enums.dart' hide QuestionStatus;
import 'package:buzz5_quiz_app/models/question_model.dart';

/// A class representing a Set of questions.
class SetModel {
  final String id;
  final String name;
  final String description;

  final String authorId;
  final String authorName;
  final List<PredefinedTags> tags;
  final DateTime creationDate;

  // New fields for marketplace and stats
  final double? price;
  final int downloads;
  final double rating;
  final DifficultyLevel? difficulty;
  final bool isPrivate;

  // Lineage tracking fields for marketplace copy/fork strategy
  /// The ID of the original set if this is a copy from the marketplace.
  final String? originalSetId;

  /// The UID of the original creator (for attribution).
  final String? originalAuthorId;

  /// The display name of the original creator (for attribution display).
  final String? originalAuthorName;

  /// True if this set is a downloaded copy and has been modified.
  final bool isRemix;

  /// Controls whether this set can be published to the marketplace.
  /// False for downloaded sets (prevents republishing others' work).
  /// True for organically created sets.
  final bool canBePublished;

  // The list of questions
  final List<Question> questions;

  SetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.authorName,
    this.tags = const [],
    DateTime? creationDate,
    this.price,
    this.downloads = 0,
    this.rating = 0.0,
    this.difficulty,
    this.isPrivate = true,
    this.originalSetId,
    this.originalAuthorId,
    this.originalAuthorName,
    this.isRemix = false,
    this.canBePublished = true,
    this.questions = const [],
  }) : creationDate = creationDate ?? DateTime.now(),
       assert(
         questions.length <= 5,
         'A set can have a maximum of 5 questions.',
       );

  /// Dynamic getter for the status.
  /// A set is complete only if it has exactly 5 questions and all are published.
  SetStatus get status {
    // A set must have a valid name and description.
    if (name.trim().isEmpty || description.trim().isEmpty) {
      return SetStatus.draft;
    }

    // A set must have exactly 5 questions to be considered complete.
    if (questions.length != 5) {
      return SetStatus.draft;
    }

    // Additionally, every question within the set must be 'published'.
    for (final question in questions) {
      if (question.status != QuestionStatus.complete) {
        return SetStatus.draft;
      }
    }

    // If all checks pass, the set is complete.
    return SetStatus.complete;
  }

  // Get number of questions
  int get questionCount => questions.length;

  /// Validates if the current privacy setting is valid.
  /// A set cannot be public (isPrivate = false) if it's in draft status.
  bool get isValidPrivacySetting {
    if (!isPrivate && status == SetStatus.draft) {
      return false;
    }
    return true;
  }

  /// Returns true if the set can be listed in the marketplace.
  /// A set can only be listed if it's not private, has complete status,
  /// and is allowed to be published (not a downloaded copy).
  bool get canBeListedInMarketplace {
    return !isPrivate && status == SetStatus.complete && canBePublished;
  }

  /// Returns true if this set was downloaded from the marketplace (has lineage).
  bool get isDownloadedFromMarketplace => originalSetId != null;

  // Factory constructor to create a SetModel from a JSON object
  factory SetModel.fromJson(Map<String, dynamic> json) {
    // Parse tags from either enum strings (e.g., "PredefinedTags.world") or plain strings (e.g., "world")
    List<PredefinedTags> parseTags(List<dynamic>? tagsList) {
      if (tagsList == null) return [];

      return tagsList
          .map<PredefinedTags?>((tag) {
            if (tag is PredefinedTags) {
              return tag;
            }

            final String tagString = tag.toString();

            // Try to find the enum value by matching the string
            // This handles both "PredefinedTags.world" and "world"
            return PredefinedTags.values.firstWhere(
              (e) {
                final enumString = e.toString(); // e.g., "PredefinedTags.world"
                final enumName = enumString.split('.').last; // e.g., "world"

                // Match either the full string or just the enum name
                return enumString == tagString || enumName == tagString;
              },
              orElse:
                  () =>
                      PredefinedTags
                          .general, // Default to 'general' if not found
            );
          })
          .whereType<PredefinedTags>()
          .toList(); // Filter out any nulls
    }

    return SetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      tags: parseTags(json['tags'] as List<dynamic>?),
      creationDate: DateTime.parse(json['creationDate'] as String),
      price: json['price'] as double?,
      downloads: json['downloads'] as int? ?? 0,
      rating: json['rating'] as double? ?? 0.0,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      isPrivate: json['isPrivate'] as bool? ?? true,
      // Lineage tracking fields
      originalSetId: json['originalSetId'] as String?,
      originalAuthorId: json['originalAuthorId'] as String?,
      originalAuthorName: json['originalAuthorName'] as String?,
      isRemix: json['isRemix'] as bool? ?? false,
      canBePublished: json['canBePublished'] as bool? ?? true,
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
      'authorId': authorId,
      'authorName': authorName,
      'tags': tags.map((tag) => tag.toString()).toList(),
      'status': status.toString(),
      'creationDate': creationDate.toIso8601String(),
      'price': price,
      'downloads': downloads,
      'rating': rating,
      'difficulty': difficulty?.toString(),
      'isPrivate': isPrivate,
      // Lineage tracking fields
      'originalSetId': originalSetId,
      'originalAuthorId': originalAuthorId,
      'originalAuthorName': originalAuthorName,
      'isRemix': isRemix,
      'canBePublished': canBePublished,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
