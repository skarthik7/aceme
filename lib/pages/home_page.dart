import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/summarizer.dart';
import 'package:aceme/pages/testme.dart';
import 'package:aceme/pages/planner.dart';
import 'package:aceme/pages/account.dart';
import 'package:aceme/pages/needhelp.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  int _selectedIndex = 2; // Set default index to 2 for Planner tab

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return SummarizerPage();
      case 1:
        return TestMePage();
      case 2:
        return PlannerPage();
      case 3:
        return NeedHelpPage();
      case 4:
        return Account(email: user?.email); // Pass the user's email
      default:
        return PlannerPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.blue,
          selectedLabelStyle: TextStyle(color: Colors.blue),
          unselectedLabelStyle: TextStyle(color: Colors.blue),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _title(),
              Row(
                children: [
                  Text(
                    '🔥 47',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  
                ],
              ),
            ],
          ),
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _getPage(_selectedIndex)), // Show the selected page here
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz),
              label: 'Test',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Planner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help),
              label: 'Help',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.blue,
          unselectedLabelStyle: TextStyle(color: Colors.blue),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
