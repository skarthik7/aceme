import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class CoursePrepPage extends StatefulWidget {
  @override
  _CoursePrepPageState createState() => _CoursePrepPageState();
}

class _CoursePrepPageState extends State<CoursePrepPage> {
  final TextEditingController _controller = TextEditingController();
  String _className = 'Welcome to Course Prep';

  void _submitClassName() {
    final courseName = _controller.text;
    _fetchCourseData(courseName);
  }

  Future<void> _fetchCourseData(String courseName) async {
    final courseParts = courseName.split(' ');
    if (courseParts.length != 2) {
      setState(() {
        _className = 'Please enter a valid course name (e.g., GURUJI 847)';
      });
      return;
    }

    final url = 'https://apps.ualberta.ca/catalogue/course/${courseParts[0]}/${courseParts[1]}';
    print('Fetching course data from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final courseElements = document.querySelectorAll('.course-title');

      setState(() {
        _className = courseElements.map((e) => e.text).join(', ');
      });
    } else {
      setState(() {
        _className = 'Failed to load course data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: InputDecoration(
                hintText: 'Search Course (e.g., GURUJI 847)',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _submitClassName,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _className,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}