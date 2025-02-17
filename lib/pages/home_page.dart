import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/summarizer.dart';
import 'package:aceme/pages/acebot.dart';
import 'package:aceme/pages/planner.dart';
import 'package:aceme/pages/account.dart';
import 'package:provider/provider.dart';
import 'package:aceme/theme_provider.dart';
import 'package:aceme/pages/courseprep.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    final random = Random();
    final randomQuote = quotes[random.nextInt(quotes.length)];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome to AceMe 😃'),
          content: Text(
            randomQuote,
            style: TextStyle(fontSize: 18), // Increase the font size here
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return SummarizerPage();
      case 1:
        return AceBoPage();
      case 2:
        return PlannerPage();
      case 3:
        return CoursePrepPage();
      case 4:
        return Account(email: user?.email);
      default:
        return PlannerPage();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: _getPage(_selectedIndex), // Show the selected page here
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'AceBot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Planner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Course Prep',
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
