import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/services/import_service.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';

void main() {
  late ImportService importService;

  setUp(() {
    importService = ImportService();
  });

  // Helper to create a CSV string from rows
  String createCsv(List<List<String>> rows) {
    return rows.map((row) => row.join(',')).join('\n');
  }

  // Helper to create a PlatformFile from CSV content
  PlatformFile createCsvFile(String content, {String name = 'test.csv'}) {
    final bytes = utf8.encode(content);
    return PlatformFile(
      name: name,
      size: bytes.length,
      bytes: bytes,
      readStream: null,
    );
  }

  group('ImportService Tests', () {
    test('parses valid CSV with 1 set of 5 questions correctly', () async {
      final csvContent = createCsv([
        [
          'set_name',
          'set_explaination',
          'points',
          'question',
          'qstn_media',
          'answer',
          'ans_media',
        ],
        ['Test Set', 'Description', '10', 'Q1', '', 'A1', ''],
        ['Test Set', 'Description', '10', 'Q2', '', 'A2', ''],
        ['Test Set', 'Description', '10', 'Q3', '', 'A3', ''],
        ['Test Set', 'Description', '10', 'Q4', '', 'A4', ''],
        ['Test Set', 'Description', '10', 'Q5', '', 'A5', ''],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 1);
      expect(result.skippedSets.length, 0);

      final set = result.validSets.first;
      expect(set.name, 'Test Set');
      expect(set.description, 'Description');
      expect(set.questions.length, 5);
      expect(set.questions[0].questionText, 'Q1');
      expect(set.questions[0].answerText, 'A1');
    });

    test('skips set with fewer than 5 questions', () async {
      final csvContent = createCsv([
        [
          'set_name',
          'set_explaination',
          'points',
          'question',
          'qstn_media',
          'answer',
          'ans_media',
        ],
        ['Incomplete Set', 'Desc', '10', 'Q1', '', 'A1', ''],
        ['Incomplete Set', 'Desc', '10', 'Q2', '', 'A2', ''],
        ['Incomplete Set', 'Desc', '10', 'Q3', '', 'A3', ''],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 0);
      expect(result.skippedSets.length, 1);
      expect(result.skippedSets.first.name, 'Incomplete Set');
      expect(result.skippedSets.first.reason, contains('requires exactly 5'));
    });

    test('validates that media can substitute for text', () async {
      final csvContent = createCsv([
        [
          'set_name',
          'set_explaination',
          'points',
          'question',
          'qstn_media',
          'answer',
          'ans_media',
        ],
        ['Mixed Set', 'Desc', '10', 'Q1', '', 'A1', ''],
        [
          'Mixed Set',
          'Desc',
          '10',
          '',
          'http://q.jpg',
          'A2',
          '',
        ], // No q-text, has q-media (Valid)
        [
          'Mixed Set',
          'Desc',
          '10',
          'Q3',
          '',
          '',
          'http://a.jpg',
        ], // No a-text, has a-media (Valid)
        [
          'Mixed Set',
          'Desc',
          '10',
          '',
          'http://q.jpg',
          '',
          'http://a.jpg',
        ], // Both missing text (Valid)
        ['Mixed Set', 'Desc', '10', 'Q5', '', 'A5', ''],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 1);
      expect(result.validSets.first.name, 'Mixed Set');
      expect(result.skippedSets.length, 0);
    });

    test('skips set when neither text nor media is present', () async {
      final csvContent = createCsv([
        [
          'set_name',
          'set_explaination',
          'points',
          'question',
          'qstn_media',
          'answer',
          'ans_media',
        ],
        ['Bad Set', 'Desc', '10', 'Q1', '', 'A1', ''],
        [
          'Bad Set',
          'Desc',
          '10',
          '',
          '',
          'A2',
          '',
        ], // Missing question AND media (Invalid)
        ['Bad Set', 'Desc', '10', 'Q3', '', 'A3', ''],
        ['Bad Set', 'Desc', '10', 'Q4', '', 'A4', ''],
        ['Bad Set', 'Desc', '10', 'Q5', '', 'A5', ''],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 0);
      expect(result.skippedSets.length, 1);
      expect(result.skippedSets.first.reason, contains('missing content'));
    });

    test('parses multiple sets correctly', () async {
      final csvContent = createCsv([
        [
          'set_name',
          'set_explaination',
          'points',
          'question',
          'qstn_media',
          'answer',
          'ans_media',
        ],
        // Set 1 (Valid)
        ['Set 1', 'Desc 1', '10', 'Q1', '', 'A1', ''],
        ['Set 1', 'Desc 1', '10', 'Q2', '', 'A2', ''],
        ['Set 1', 'Desc 1', '10', 'Q3', '', 'A3', ''],
        ['Set 1', 'Desc 1', '10', 'Q4', '', 'A4', ''],
        ['Set 1', 'Desc 1', '10', 'Q5', '', 'A5', ''],
        // Set 2 (Invalid - 4 qs)
        ['Set 2', 'Desc 2', '10', 'Q1', '', 'A1', ''],
        ['Set 2', 'Desc 2', '10', 'Q2', '', 'A2', ''],
        ['Set 2', 'Desc 2', '10', 'Q3', '', 'A3', ''],
        ['Set 2', 'Desc 2', '10', 'Q4', '', 'A4', ''],
        // Set 3 (Valid)
        ['Set 3', 'Desc 3', '10', 'Q1', '', 'A1', ''],
        ['Set 3', 'Desc 3', '10', 'Q2', '', 'A2', ''],
        ['Set 3', 'Desc 3', '10', 'Q3', '', 'A3', ''],
        ['Set 3', 'Desc 3', '10', 'Q4', '', 'A4', ''],
        ['Set 3', 'Desc 3', '10', 'Q5', '', 'A5', ''],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 2);
      expect(result.skippedSets.length, 1);
      expect(result.validSets[0].name, 'Set 1');
      expect(result.skippedSets[0].name, 'Set 2');
      expect(result.validSets[1].name, 'Set 3');
    });

    test('handles different column names (case insensitive)', () async {
      final csvContent = createCsv([
        [
          'SET NAME',
          'explanation',
          'Score',
          'Question Text',
          'q_media',
          'Answer Text',
          'a_media',
        ],
        ['Test Set', 'Desc', '20', 'Q1', '', 'A1', ''],
        ['Test Set', 'Desc', '20', 'Q2', '', 'A2', ''],
        ['Test Set', 'Desc', '20', 'Q3', '', 'A3', ''],
        ['Test Set', 'Desc', '20', 'Q4', '', 'A4', ''],
        ['Test Set', 'Desc', '20', 'Q5', '', 'A5', ''],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 1);
      expect(result.validSets.first.questions.first.points, 20);
    });

    test('parses difficulty correctly', () async {
      final csvContent = createCsv([
        ['set_name', 'difficulty', 'question', 'answer'],
        ['Hard Set', 'Hard', 'Q1', 'A1'],
        ['Hard Set', 'Hard', 'Q2', 'A2'],
        ['Hard Set', 'Hard', 'Q3', 'A3'],
        ['Hard Set', 'Hard', 'Q4', 'A4'],
        ['Hard Set', 'Hard', 'Q5', 'A5'],
      ]);

      final file = createCsvFile(csvContent);
      final result = await importService.parseFile(file);

      expect(result.validSets.length, 1);
      expect(result.validSets.first.difficulty, DifficultyLevel.hard);
    });

    test('throws error for missing required columns', () async {
      final csvContent = createCsv([
        ['set_description', 'points'], // Missing set_name, question, answer
        ['Desc', '10'],
      ]);

      final file = createCsvFile(csvContent);

      expect(
        () async => await importService.parseFile(file),
        throwsA(isA<Exception>()),
      );
    });
  });
}
