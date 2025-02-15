import 'package:flutter/material.dart';

class SummarizerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Summarizer'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Note Summarizer Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}