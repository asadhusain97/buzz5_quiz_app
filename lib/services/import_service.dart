import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';

/// Class to hold the result of an import operation
class ImportResult {
  final List<ParsedSet> validSets;
  final List<SkippedSet> skippedSets;
  final int totalRowsRead;

  ImportResult({
    required this.validSets,
    required this.skippedSets,
    required this.totalRowsRead,
  });
}

/// A set that has been parsed and validated
class ParsedSet {
  final String name;
  final String description;
  final DifficultyLevel difficulty;
  final List<ParsedQuestion> questions;

  ParsedSet({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.questions,
  });
}

/// A question that has been parsed
class ParsedQuestion {
  final String questionText;
  final String? questionMediaUrl;
  final String answerText;
  final String? answerMediaUrl;
  final int points;

  ParsedQuestion({
    required this.questionText,
    this.questionMediaUrl,
    required this.answerText,
    this.answerMediaUrl,
    required this.points,
  });
}

/// A set that was skipped due to validation errors
class SkippedSet {
  final String name;
  final String reason;

  SkippedSet({required this.name, required this.reason});
}

/// Service to handle parsing and validation of import files
class ImportService {
  /// Parse a file (Excel or CSV) and return Valid/Skipped sets
  Future<ImportResult> parseFile(PlatformFile file) async {
    try {
      final String extension = file.extension?.toLowerCase() ?? '';
      List<List<dynamic>> rows = [];

      AppLogger.i('Parsing file: ${file.name} (Size: ${file.size} bytes)');

      if (extension == 'csv') {
        rows = await _parseCsv(file);
      } else {
        throw Exception('Unsupported file format. Please use .csv');
      }

      AppLogger.i('Parsed ${rows.length} rows (including header)');
      return _processRows(rows);
    } catch (e, stackTrace) {
      AppLogger.e('Error parsing file: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Parse CSV file content
  Future<List<List<dynamic>>> _parseCsv(PlatformFile file) async {
    final input =
        file.bytes != null
            ? utf8.decode(file.bytes!)
            : await File(file.path!).readAsString();

    return const CsvToListConverter().convert(input, eol: '\n');
  }

  /// Process raw rows into sets
  ImportResult _processRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      return ImportResult(validSets: [], skippedSets: [], totalRowsRead: 0);
    }

    // 1. Identify headers and map them to indices
    final headers =
        rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final Map<String, int> colMap = {};

    // Expected columns mapping
    final expectedCols = {
      'set_name': ['set_name', 'name', 'set name'],
      'set_description': [
        'set_explaination',
        'description',
        'set description',
        'explanation',
        'set_explanation',
        'set explanation',
      ],
      'difficulty': ['difficulty', 'level', 'difficulty_level'],
      'points': ['points', 'score'],
      'question': ['question', 'question text', 'question_text'],
      'question_media': ['qstn_media', 'question media', 'question_media_url'],
      'answer': ['answer', 'answer text', 'answer_text'],
      'answer_media': ['ans_media', 'answer media', 'answer_media_url'],
    };

    // Find indices
    for (var key in expectedCols.keys) {
      for (var alias in expectedCols[key]!) {
        final index = headers.indexOf(alias);
        if (index != -1) {
          colMap[key] = index;
          break;
        }
      }
    }

    // Validation: Check required columns
    final requiredCols = ['set_name', 'question', 'answer'];
    for (var col in requiredCols) {
      if (!colMap.containsKey(col)) {
        throw Exception(
          'Missing required column: $col. Please check the template.',
        );
      }
    }

    // 2. Group rows by set name
    final Map<String, List<ParsedQuestion>> setQuestions = {};
    final Map<String, String> setDescriptions =
        {}; // Store description for each set
    final Map<String, DifficultyLevel> setDifficulties =
        {}; // Store difficulty for each set

    // Skip header row
    int dataRows = 0;
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      // Get set name
      final nameIdx = colMap['set_name']!;
      if (nameIdx >= row.length) continue;

      final setName = row[nameIdx].toString().trim();
      if (setName.isEmpty) continue;

      // Capture description (only need to do it once per set, but fine to overwrite)
      if (colMap.containsKey('set_description')) {
        final descIdx = colMap['set_description']!;
        if (descIdx < row.length) {
          final desc = row[descIdx].toString().trim();
          if (desc.isNotEmpty) {
            setDescriptions[setName] = desc;
          }
        }
      }

      // Capture difficulty (only need to do it once per set)
      if (colMap.containsKey('difficulty')) {
        final diffIdx = colMap['difficulty']!;
        if (diffIdx < row.length) {
          final diffStr = row[diffIdx].toString().trim();
          if (diffStr.isNotEmpty) {
            setDifficulties[setName] = _parseDifficulty(diffStr);
          }
        }
      }

      // Extract question data
      final questionText = _getCellValue(row, colMap['question']);
      final answerText = _getCellValue(row, colMap['answer']);

      // Skip incomplete rows (but don't fail the whole set - just skip this question)
      // Actually, user said: "If required fields are missing then skip it as well [the set likely]"
      // Let's collect all questions, then validate set count.

      // Get optional fields
      String? qMedia = _getCellValue(row, colMap['question_media']);
      if (qMedia != null && qMedia.isEmpty) qMedia = null;

      String? aMedia = _getCellValue(row, colMap['answer_media']);
      if (aMedia != null && aMedia.isEmpty) aMedia = null;

      int points = 10;
      final pointsStr = _getCellValue(row, colMap['points']);
      if (pointsStr != null && pointsStr.isNotEmpty) {
        points = int.tryParse(pointsStr) ?? 10;
      }

      final question = ParsedQuestion(
        questionText: questionText ?? '',
        questionMediaUrl: qMedia,
        answerText: answerText ?? '',
        answerMediaUrl: aMedia,
        points: points,
      );

      setQuestions.putIfAbsent(setName, () => []).add(question);
      dataRows++;
    }

    // 3. Validate sets
    final List<ParsedSet> validSets = [];
    final List<SkippedSet> skippedSets = [];

    setQuestions.forEach((setName, questions) {
      // Rule: Each set must have exactly 5 questions
      if (questions.length != 5) {
        skippedSets.add(
          SkippedSet(
            name: setName,
            reason: 'Found ${questions.length} questions (requires exactly 5)',
          ),
        );
        return;
      }

      // Rule: Check for missing required fields in any question
      bool hasErrors = false;
      for (int j = 0; j < questions.length; j++) {
        final q = questions[j];

        // Logical check: Is there content for Q? (Text OR Media)
        bool hasQuestionContent =
            q.questionText.isNotEmpty ||
            (q.questionMediaUrl != null && q.questionMediaUrl!.isNotEmpty);

        // Logical check: Is there content for A? (Text OR Media)
        bool hasAnswerContent =
            q.answerText.isNotEmpty ||
            (q.answerMediaUrl != null && q.answerMediaUrl!.isNotEmpty);

        if (!hasQuestionContent || !hasAnswerContent) {
          skippedSets.add(
            SkippedSet(
              name: setName,
              reason:
                  'Question ${j + 1} is missing content (must have text or media for both Q & A)',
            ),
          );
          hasErrors = true;
          break;
        }
      }
      if (hasErrors) return;

      // Valid set!
      validSets.add(
        ParsedSet(
          name: setName,
          description: setDescriptions[setName] ?? '',
          difficulty: setDifficulties[setName] ?? DifficultyLevel.medium,
          questions: questions,
        ),
      );
    });

    return ImportResult(
      validSets: validSets,
      skippedSets: skippedSets,
      totalRowsRead: dataRows,
    );
  }

  String? _getCellValue(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return null;
    return row[index].toString().trim();
  }

  DifficultyLevel _parseDifficulty(String value) {
    final v = value.toLowerCase().trim();
    if (v == 'easy') return DifficultyLevel.easy;
    if (v == 'hard') return DifficultyLevel.hard;
    return DifficultyLevel.medium;
  }
}
