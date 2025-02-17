import 'package:flutter/material.dart';

class TestMePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TestMe'),
      ),
      body: Center(
        child: Text(
          'Welcome to the TestMe Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}