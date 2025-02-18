import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aceme/font_size_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AceBoPage extends StatefulWidget {
  @override
  _AceBoPageState createState() => _AceBoPageState();
}

class _AceBoPageState extends State<AceBoPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String _apiKey = 'KEY-HERE';
  final ScrollController _scrollController = ScrollController();
  bool _isQuizMode = false;
  bool _isExpectingQuizResponse = false;
  bool _isLoading = false;
  String _loadingText = '.';
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _loadingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        if (_loadingText == '.') {
          _loadingText = '..';
        } else if (_loadingText == '..') {
          _loadingText = '...';
        } else if (_loadingText == '...') {
          _loadingText = '....';
        } else {
          _loadingText = '.';
        }
      });
    });
  }

  void _stopLoadingAnimation() {
    _loadingTimer?.cancel();
    setState(() {
      _loadingText = '.';
    });
  }

  Future<void> _sendMessage(String message, {bool displayMessage = true}) async {
    if (displayMessage) {
      setState(() {
        _messages.add({'role': 'user', 'text': message});
        _isLoading = true;
      });
      _startLoadingAnimation();
      _saveMessages();
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
        _isExpectingQuizResponse = _isQuizMode;
        _isLoading = false;
      });
    } else {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Error: ${response.reasonPhrase}'});
        _isLoading = false;
      });
    }

    _stopLoadingAnimation();
    _scrollToBottom();
    _saveMessages();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messages = _messages.map((message) => json.encode(message)).toList();
    prefs.setStringList('messages', messages);
  }

  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messages = prefs.getStringList('messages');
    if (messages != null) {
      setState(() {
        _messages.addAll(messages.map((message) => Map<String, String>.from(json.decode(message) as Map)).toList().cast<Map<String, String>>());
      });
    }
  }

  void _clearMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('messages');
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('AceBot'),
        centerTitle: true,
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
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child: Text(
                            _loadingText,
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: fontSizeProvider.fontSize),
                          ),
                        ),
                      );
                    }

                    final message = _messages[index];

                    return Align(
                      alignment: message['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? (message['role'] == 'user' ? Colors.blue : Colors.black) 
                              : (message['role'] == 'user' ? Colors.blue[200] : Colors.grey[300]),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomLeft: message['role'] == 'user'
                                ? Radius.circular(15)
                                : Radius.circular(0),
                            bottomRight: message['role'] == 'user'
                                ? Radius.circular(0)
                                : Radius.circular(15),
                          ),
                        ),
                        child: message['role'] == 'user'
                            ? Text(
                                message['text']!,
                                style: TextStyle(color: Colors.black, fontSize: fontSizeProvider.fontSize),
                              )
                            : MarkdownBody(
                                data: message['text']!,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: fontSizeProvider.fontSize),
                                ),
                              ),
                      ),
                    );
                  },
                ),
                if (_messages.isEmpty)
                  Center(
                    child: Text(
                      'What can I help with?',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.grey),
                    ),
                  ),
              ],
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
                      label: Text('TestMe: Upload PDF', style: TextStyle(fontSize: fontSizeProvider.fontSize)),
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
                        color: isDarkMode ? Colors.blue : Color(0xFFC3ECFE),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: fontSizeProvider.fontSize),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: fontSizeProvider.fontSize),
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
