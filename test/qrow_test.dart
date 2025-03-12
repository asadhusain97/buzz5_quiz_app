import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:buzz5_quiz_app/models/qrow.dart';

void main() {
  group('QRow.fetchAll', () {
    test(
      'returns a list of QRow if the http call completes successfully',
      () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'qid': '1',
                'round': 'Round 1',
                'set_name': 'Set 1',
                'points': 10,
                'question': 'What is Flutter?',
                'qstn_media': 'media1',
                'answer': 'A UI toolkit',
                'ans_media': 'media2',
              },
            ]),
            200,
          );
        });

        // Override the http.Client used in QRow.fetchAll
        final response = await QRow.fetchAll(client: client);

        expect(response, isA<List<QRow>>());
        expect(response.length, 1);
        expect(response[0].points, 10);
      },
    );

    test('throws an exception if the http call completes with an error', () {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      expect(QRow.fetchAll(client: client), throwsException);
    });
  });
}
