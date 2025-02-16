import 'dart:math';
import 'package:flutter/material.dart';

class PlannerPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
           
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 121, 201, 239),
              borderRadius: BorderRadius.circular(15),
              //border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Text(
              getRandomQuote(),
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          // Add the rest of your PlannerPage content here
        ],
      ),
    );
  }
}