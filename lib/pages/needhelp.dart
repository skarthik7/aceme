import 'package:flutter/material.dart';

class NeedHelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Need Help?'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Need Help Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}