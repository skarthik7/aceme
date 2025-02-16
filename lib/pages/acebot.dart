import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';

class AceBoPage extends StatefulWidget {
  @override
  _AceBoPageState createState() => _AceBoPageState();
}

class _AceBoPageState extends State<AceBoPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String _apiKey = 'YOUR_API_KEY_HERE';
  bool _isQuizMode = false;
  bool _isExpectingQuizResponse = false;

  Future<void> _sendMessage(String message, {bool displayMessage = true}) async {
    if (displayMessage) {
      setState(() {
        _messages.add({'role': 'user', 'text': message});
      });
    }

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String reply = (data['candidates']?.isNotEmpty ?? false) &&
              (data['candidates']?[0]['content']['parts']?.isNotEmpty ?? false)
          ? data['candidates']![0]['content']['parts'][0]['text']
          : 'Failed to generate response';

      setState(() {
        _messages.add({'role': 'bot', 'text': reply});
        _isExpectingQuizResponse = _isQuizMode; // Set the flag if in quiz mode
      });
    } else {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Error: ${response.reasonPhrase}'});
      });
    }
  }

  Future<void> _uploadPdfAndGenerateQuiz() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String pdfName = result.files.single.name;
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Quizzing on $pdfName'});
      });

      PDFDoc doc = await PDFDoc.fromFile(file);
      String text = await doc.text;
      _sendMessage("ask me 10 mcqs and give answers from this pdf: $text", displayMessage: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('AceBot'),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isQuizMode ? Icons.chat : Icons.quiz),
            onPressed: () {
              setState(() {
                _isQuizMode = !_isQuizMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: message['role'] == 'user'
                      ? Text(
                          message['text']!,
                          style: TextStyle(color: Colors.blue),
                        )
                      : MarkdownBody(
                          data: message['text']!,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                );
              },
            ),
          ),
          if (_isQuizMode && !_isExpectingQuizResponse)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.attach_file),
                      label: Text('Upload PDF'),
                      onPressed: _uploadPdfAndGenerateQuiz,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFC3ECFE), // Set the background color to light blue
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        _sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}