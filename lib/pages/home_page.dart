import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/summarizer.dart';
import 'package:aceme/pages/acebot.dart';
import 'package:aceme/pages/planner.dart';
import 'package:aceme/pages/account.dart';
import 'package:aceme/pages/needhelp.dart';
import 'package:provider/provider.dart';
import 'package:aceme/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    double sliderValue = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getRandomQuote()),
              SizedBox(height: 20),
              Text('Swipe to ace!'),
              SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setState) {
                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        sliderValue += details.primaryDelta! / 200;
                        if (sliderValue >= 1.0) {
                          sliderValue = 1.0;
                          Navigator.of(context).pop();
                        } else if (sliderValue < 0.0) {
                          sliderValue = 0.0;
                        }
                      });
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: sliderValue * (MediaQuery.of(context).size.width - 100),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  sliderValue == 1.0 ? 'Done' : 'Swipe',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
        return AceBoPage();
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
              icon: Icon(Icons.chat),
              label: 'AceBot',
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
