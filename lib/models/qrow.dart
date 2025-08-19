import 'dart:convert';

import 'package:buzz5_quiz_app/config/app_config.dart';
import 'package:http/http.dart' as http;

class QRow {
  final int qid;
  final String round;
  final String setName;
  final int points;
  final String question;
  final String qstnMedia;
  final dynamic answer;
  final String ansMedia;
  final String setExplanation;
  final String setExampleQuestion;
  final String setExampleAnswer;

  QRow({
    required this.qid,
    required this.round,
    required this.setName,
    required this.points,
    required this.question,
    required this.qstnMedia,
    required this.answer,
    required this.ansMedia,
    this.setExplanation = "This category covers various topics and themes.",
    this.setExampleQuestion = "What is an example question from this category?",
    this.setExampleAnswer = "This would be an example answer.",
  });

  factory QRow.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return QRow(
      qid: parseInt(json['qid']),
      round: json['round'] ?? '',
      setName: json['set_name'] ?? '',
      points: parseInt(json['points']),
      question: json['question'] ?? '',
      qstnMedia: json['qstn_media'] ?? '',
      answer: json['answer'],
      ansMedia: json['ans_media'] ?? '',
      setExplanation:
          json['set_explanation'] ??
          "This category covers various topics and themes.",
      setExampleQuestion:
          json['set_example_question'] ??
          "What is an example question from this category?",
      setExampleAnswer:
          json['set_example_answer'] ?? "This would be an example answer.",
    );
  }

  static Future<List<QRow>> fetchAll({http.Client? client}) async {
    client ??= http.Client();
    final response = await client.get(Uri.parse(AppConfig.googleSheetApiKey));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => QRow.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data from google sheet');
    }
  }

  static List<QRow> filterByRound(List<QRow> qrows, String round) {
    return qrows.where((qrow) => qrow.round == round).toList();
  }

  static List<QRow> filterBySetName(List<QRow> qrows, String setName) {
    return qrows.where((qrow) => qrow.setName == setName).toList();
  }

  static List<String> getUniqueRounds(List<QRow> qrows) {
    return qrows.map((qrow) => qrow.round).toSet().toList();
  }

  static List<String> getUniqueSetNames(List<QRow> qrows) {
    return qrows.map((qrow) => qrow.setName).toSet().toList();
  }
}
