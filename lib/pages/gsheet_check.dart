import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/models/qrow.dart';

class GSheetCheckPage extends StatefulWidget {
  const GSheetCheckPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GSheetCheckPageState createState() => _GSheetCheckPageState();
}

class _GSheetCheckPageState extends State<GSheetCheckPage> {
  late Future<List<QRow>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = QRow.fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: AppBar(title: Text('GSheet Data Check')),
      child: FutureBuilder<List<QRow>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data found'));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text('QID: ${item.qid}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Round: ${item.round}'),
                      Text('Set Name: ${item.setName}'),
                      Text('Points: ${item.points}'),
                      Text('Question: ${item.question}'),
                      Text('Question Media: ${item.qstnMedia}'),
                      Text('Answer: ${item.answer}'),
                      Text('Answer Media: ${item.ansMedia}'),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
