import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class AceBoPage extends StatefulWidget {
  @override
  _AceBoPageState createState() => _AceBoPageState();
}

class _AceBoPageState extends State<AceBoPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String _apiKey = 'AIzaSyDEit47_ToU42NqvYTk_VN1jg5rVegRllo';

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'text': message});
    });

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
      });
    } else {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Error: ${response.reasonPhrase}'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AceBot'),
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
                            p: TextStyle(color: Colors.black),
                          ),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
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