import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SummarizerPage extends StatefulWidget {
  @override
  _SummarizerPageState createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<SummarizerPage> {
  final String _apiKey = 'AIzaSyDEit47_ToU42NqvYTk_VN1jg5rVegRllo';
  List<Map<String, dynamic>> _pdfList = [];
  String? _userEmail; 

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  /// Get the currently logged-in user's email
  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    print(user);
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
      _loadSummaries();
    }
  }

  /// Fetches stored summaries for the logged-in user
  Future<void> _loadSummaries() async {
    if (_userEmail == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('summaries')
        .where('email', isEqualTo: _userEmail) // Fetch only user's summaries
        .get();

    setState(() {
      _pdfList = snapshot.docs.map((doc) {
        return {
          'user': _userEmail,
          'name': doc['name'],
          'summary': doc['summary'],
        };
      }).toList();
    });
  }

  /// Opens a dialog to enter a name for the PDF
  Future<String?> _promptForPdfName() async {
    String? pdfName;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Enter PDF Name and Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: 'PDF Name'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  pdfName = controller.text;
                  Navigator.of(context).pop();
                },
                child: Text('Upload PDF'),
              ),
            ],
          ),
        );
      },
    );
    return pdfName;
  }

  /// Picks a PDF, extracts text, and sends it for summarization
  Future<void> _pickAndExtractPdf() async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in!')),
      );
      return;
    }

    String? pdfName = await _promptForPdfName();
    if (pdfName != null && pdfName.isNotEmpty) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        PDFDoc doc = await PDFDoc.fromFile(file);
        String text = await doc.text;
        _summarizeText(text, pdfName);
      }
    }
  }

  /// Calls Gemini AI API to summarize text and stores result in Firestore
  Future<void> _summarizeText(String text, String pdfName) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': 'Summarize the following text: $text'}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String summary = (data['candidates']?.isNotEmpty ?? false) &&
              (data['candidates'][0]['content']['parts']?.isNotEmpty ?? false)
          ? data['candidates'][0]['content']['parts'][0]['text']
          : 'Failed to generate summary';

      // Store summary in Firestore with user's email
      await FirebaseFirestore.instance.collection('summaries').add({
        'name': pdfName,
        'summary': summary,
        'email': _userEmail, // Store user email
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update UI
      setState(() {
        _pdfList.add({'name': pdfName, 'summary': summary});
      });
    } else {
      setState(() {
        _pdfList.add({'name': pdfName, 'summary': 'Error: ${response.reasonPhrase}'});
      });
    }
  }

  /// Displays a dialog with the summary text
  void _viewSummary(String summary) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Summary'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes Summarizer'), backgroundColor: Colors.blue,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _pdfList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_pdfList[index]['name']!),
                    trailing: ElevatedButton(
                      onPressed: () => _viewSummary(_pdfList[index]['summary']!),
                      child: Text('View Summary'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndExtractPdf,
        child: Icon(Icons.add),
      ),
    );
  }
}