import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aceme/pages/planner.dart'; // Import the PlannerPage

class NeedHelpPage extends StatefulWidget {
  @override
  _NeedHelpPageState createState() => _NeedHelpPageState();
}

class _NeedHelpPageState extends State<NeedHelpPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _sliderValue = 0;

  final List<String> questions = [
    "How often do you feel overwhelmed with your studies?",
    "How often do you have trouble concentrating or staying motivated?",
    "How often do you feel anxious about exams or assignments?",
    "How often do you struggle to enjoy things you used to like?",
    "How often do you struggle with sleep, either too much or too little?",
    "How often do you experience stress that feels unmanageable?",
    "How often do you skip meals or overeat due to stress?",
  ];

  void _nextPage() {
    if (_currentPage < questions.length) {
      setState(() {
        _currentPage++;
        _sliderValue = 0;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Show submission message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Thank you!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("It looks like you might be feeling overwhelmed. \n\nYou're not alone - many students feel this way. Would you like to check out some professional support options?"),
              SizedBox(height: 10),
              Text("We recommend talking to our partners:"),
              GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse('https://www.betterhelp.com/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BetterHelp',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.link, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Thanks for submitting"),
                    content: Text("We will contact you soon."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => PlannerPage()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text("OK"),
                      ),
                    ],
                  ),
                );
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Need Help?'),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        itemCount: questions.length + 1, // Add one for the introductory page
        itemBuilder: (context, index) {
          if (index == 0) {
            // Introductory page
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "We will ask you a few questions to assist you better.",
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: _nextPage,
                    child: Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            );
          } else {
            // Question pages
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    questions[index - 1], // Adjust index for questions
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Slider(
                    value: _sliderValue,
                    min: 0,
                    max: 4,
                    divisions: 4,
                    activeColor: Colors.blue,
                    label: _sliderValue == 0
                        ? 'Never'
                        : _sliderValue == 1
                            ? 'Rarely'
                            : _sliderValue == 2
                                ? 'Sometimes'
                                : _sliderValue == 3
                                    ? 'Often'
                                    : 'Always',
                    onChanged: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      index < questions.length ? "Next" : "Submit",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}