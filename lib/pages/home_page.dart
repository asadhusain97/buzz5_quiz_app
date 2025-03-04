import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Function(bool) onThemeChanged;

  HomePage({required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buzz5 Quiz'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              onThemeChanged(value);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to the Home Page!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              child: Text('Button 1'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              child: Text('Button 2'),
            ),
          ],
        ),
      ),
    );
  }
}
