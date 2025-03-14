import 'dart:convert';

import 'package:buzz5_quiz_app/config/secrets.dart';
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

  QRow({
    required this.qid,
    required this.round,
    required this.setName,
    required this.points,
    required this.question,
    required this.qstnMedia,
    required this.answer,
    required this.ansMedia,
  });

  factory QRow.fromJson(Map<String, dynamic> json) {
    return QRow(
      qid: json['qid'],
      round: json['round'],
      setName: json['set_name'],
      points: json['points'],
      question: json['question'],
      qstnMedia: json['qstn_media'],
      answer: json['answer'],
      ansMedia: json['ans_media'],
    );
  }

  static Future<List<QRow>> fetchAll({http.Client? client}) async {
    client ??= http.Client();
    final response = await client.get(Uri.parse(Secrets.GSheetAPI));

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
