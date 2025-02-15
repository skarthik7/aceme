import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/summarizer.dart';
import 'package:aceme/pages/testme.dart';
import 'package:aceme/pages/planner.dart';
import 'package:aceme/pages/askme.dart';
import 'package:aceme/pages/needhelp.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  final List<String> quotes = [
    "Success starts with self-discipline.",  
    "Small steps lead to big achievements.",  
    "Your future is created by what you do today.",  
    "Dream big, study hard, stay focused.",  
    "Failure is proof that you’re trying.",  
    "The only limit is the one you set.",  
    "Learn like you’ll live forever.",  
    "Consistency beats intensity.",  
    "You don’t have to be perfect, just progress.",  
    "Effort today, success tomorrow.",  
    "Study now, shine later.",  
    "Knowledge is your superpower.",  
    "Push yourself, no one else will.",  
    "The best investment is in yourself.",  
    "Winners never quit, quitters never win.",  
    "Every mistake is a lesson.",  
    "You are capable of more than you know.",  
    "Stay hungry for knowledge.",  
    "Believe in yourself and all that you are.",  
    "Hard work beats talent when talent doesn’t work hard.",
  ];

  String getRandomQuote() {
    final random = Random();
    int index = random.nextInt(quotes.length);
    return quotes[index];
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  String _getUsername(String? email) {
    if (email == null) return 'User';
    return email.split('@')[0];
  }

  Widget _title() {
    return Text('AceMe');
  }

  Widget _userUid() {
    return Text(_getUsername(user?.email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: _title(),
        actions: <Widget>[
          Center(
            child: Row(
              children: [
                _userUid(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.arrow_drop_down),
                  onSelected: (String result) {
                    if (result == 'settings') {
                      // Navigate to account settings
                    } else if (result == 'logout') {
                      signOut();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Text('View Account'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🔥 47',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              getRandomQuote(),
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildOptionBox(context, 'Note Summarizer', SummarizerPage())),
                SizedBox(width: 10),
                Expanded(child: _buildOptionBox(context, 'TestMe', TestMePage())),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildOptionBox(context, 'Planner', PlannerPage())),
                SizedBox(width: 10),
                Expanded(child: _buildOptionBox(context, 'AskMe', AskMePage())),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildHelpBox(context)),
              ],
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionBox(BuildContext context, String title, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        height: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpBox(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NeedHelpPage()),
        );
      },
      child: Container(
        height: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Need help? We're always here for you",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Powered by',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(width: 10),
                Image.asset(
                  'assets/images/betterhelp-logo-square.png',
                  height: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
