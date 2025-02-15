import 'package:flutter/material.dart';

class AskMePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AskMe'),
      ),
      body: Center(
        child: Text(
          'Welcome to the AskMe Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}