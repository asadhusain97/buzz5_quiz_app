import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum Difficulty { easy, medium, hard }

class Question {
  final String questionId;
  final String questionName;
  final String questionText;
  final String questionMedia;
  final String answerText;
  final String answerMedia;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String category;
  final List<String> tags;
  final int points;
  final String prompts;
  final String explanation;
  final bool isActive;
  final Difficulty difficulty;
  final double correctPercentage;
  final int timesUsed;

  Question({
    required this.questionId,
    required this.questionName,
    required this.questionText,
    this.questionMedia = '',
    required this.answerText,
    this.answerMedia = '',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.category,
    this.tags = const [],
    required this.points,
    this.prompts = '',
    this.explanation = '',
    required this.isActive,
    this.difficulty = Difficulty.easy,
    this.correctPercentage = 0.0,
    this.timesUsed = 0,
  });

  factory Question.create({
    required String questionName,
    required String questionText,
    String questionMedia = '',
    required String answerText,
    String answerMedia = '',
    required String createdBy,
    required String category,
    List<String> tags = const [],
    required int points,
    String prompts = '',
    String explanation = '',
    required bool isActive,
    Difficulty difficulty = Difficulty.easy,
  }) {
    final now = DateTime.now();
    return Question(
      questionId: const Uuid().v4(),
      questionName: questionName,
      questionText: questionText,
      questionMedia: questionMedia,
      answerText: answerText,
      answerMedia: answerMedia,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      category: category,
      tags: tags,
      points: points,
      prompts: prompts,
      explanation: explanation,
      isActive: isActive,
      difficulty: difficulty,
      correctPercentage: 0.0,
      timesUsed: 0,
    );
  }

  Question copyWith({
    String? questionId,
    String? questionName,
    String? questionText,
    String? questionMedia,
    String? answerText,
    String? answerMedia,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? category,
    List<String>? tags,
    int? points,
    String? prompts,
    String? explanation,
    bool? isActive,
    Difficulty? difficulty,
    double? correctPercentage,
    int? timesUsed,
  }) {
    return Question(
      questionId: questionId ?? this.questionId,
      questionName: questionName ?? this.questionName,
      questionText: questionText ?? this.questionText,
      questionMedia: questionMedia ?? this.questionMedia,
      answerText: answerText ?? this.answerText,
      answerMedia: answerMedia ?? this.answerMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      points: points ?? this.points,
      prompts: prompts ?? this.prompts,
      explanation: explanation ?? this.explanation,
      isActive: isActive ?? this.isActive,
      difficulty: difficulty ?? this.difficulty,
      correctPercentage: correctPercentage ?? this.correctPercentage,
      timesUsed: timesUsed ?? this.timesUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionName': questionName,
      'questionText': questionText,
      'questionMedia': questionMedia,
      'answerText': answerText,
      'answerMedia': answerMedia,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'category': category,
      'tags': tags,
      'points': points,
      'prompts': prompts,
      'explanation': explanation,
      'isActive': isActive,
      'difficulty': difficulty.name,
      'correctPercentage': correctPercentage,
      'timesUsed': timesUsed,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'] ?? '',
      questionName: json['questionName'] ?? '',
      questionText: json['questionText'] ?? '',
      questionMedia: json['questionMedia'] ?? '',
      answerText: json['answerText'] ?? '',
      answerMedia: json['answerMedia'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      points: json['points']?.toInt() ?? 0,
      prompts: json['prompts'] ?? '',
      explanation: json['explanation'] ?? '',
      isActive: json['isActive'] ?? false,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == (json['difficulty'] ?? 'easy'),
        orElse: () => Difficulty.easy,
      ),
      correctPercentage: (json['correctPercentage']?.toDouble()) ?? 0.0,
      timesUsed: json['timesUsed']?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.questionId == questionId;
  }

  @override
  int get hashCode => questionId.hashCode;

  @override
  String toString() {
    return 'Question{questionId: $questionId, questionName: $questionName, isActive: $isActive}';
  }
}