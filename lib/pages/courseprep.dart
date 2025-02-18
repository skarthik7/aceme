import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:aceme/font_size_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoursePrepPage extends StatefulWidget {
  @override
  _CoursePrepPageState createState() => _CoursePrepPageState();
}

class _CoursePrepPageState extends State<CoursePrepPage> {
  final TextEditingController _controller = TextEditingController();
  String _className = '';
  String _geminiResponse = '';

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  void _submitClassName() {
    final courseName = _controller.text;
    _fetchCourseData(courseName);
  }

  Future<void> _fetchCourseData(String courseName) async {
    final courseParts = courseName.split(' ');
    if (courseParts.length != 2) {
      setState(() {
        _className = 'Please enter a valid course name (e.g., GURUJI 847)';
        _geminiResponse = '';
      });
      return;
    }

    final url = 'https://apps.ualberta.ca/catalogue/course/${courseParts[0]}/${courseParts[1]}';
    print('Fetching course data from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final courseTitle = document.querySelector('h1')?.text ?? 'Course Title Not Found';
      final courseParagraphs = document.querySelectorAll('.container p'); // Adjust the selector based on actual HTML structure

      setState(() {
        _className = courseTitle;
      });

      // Send the text to Gemini API
      final courseText = courseParagraphs.map((e) => e.text).join(' ');
      _sendToGemini(courseText);
    } else {
      setState(() {
        _className = 'Invalid course name';
        _geminiResponse = '';
      });
    }
  }

  Future<void> _sendToGemini(String courseText) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=KEY-HERE';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'GIVE ME a very short list of THINGS I CAN STUDY FOR THIS COURSE BEFORE TAKING IT TO HELP ME PREPARE, and also show classes of prereq(if any) as bullet points in the top (JUST CLASS NUMBERS): $courseText'}
            ]
          }
        ]
      }),
    );

    print('Gemini API response: ${response.body}'); // Debugging line

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData != null && responseData['candidates'] != null && responseData['candidates'].isNotEmpty) {
        setState(() {
          _geminiResponse = responseData['candidates'][0]['content']['parts'][0]['text'];
        });
        _saveCourseData(_className, _geminiResponse);
      } else {
        setState(() {
          _geminiResponse = 'Invalid response from Gemini API';
        });
      }
    } else {
      setState(() {
        _geminiResponse = 'Failed to get response from Gemini API';
      });
    }
  }

  Future<void> _saveCourseData(String className, String geminiResponse) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('className', className);
    prefs.setString('geminiResponse', geminiResponse);
  }

  Future<void> _loadCourseData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _className = prefs.getString('className') ?? '';
      _geminiResponse = prefs.getString('geminiResponse') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Course Prep'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: fontSizeProvider.fontSize),
              decoration: InputDecoration(
                hintText: 'Search Course (e.g., CMPUT 175)',
                hintStyle: TextStyle(fontSize: fontSizeProvider.fontSize),
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _submitClassName,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _className,
              style: TextStyle(fontSize: fontSizeProvider.fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _geminiResponse.isEmpty
                  ? Center(
                      child: Text(
                        "Find specific course tips here! 💯",
                        style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.grey),
                      ),
                    )
                  : Markdown(
                      data: _geminiResponse,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: fontSizeProvider.fontSize),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}