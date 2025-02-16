import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';

class SummarizerPage extends StatefulWidget {
  @override
  _SummarizerPageState createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<SummarizerPage> {
  final String _apiKey = 'AIzaSyDEit47_ToU42NqvYTk_VN1jg5rVegRllo';
  List<Map<String, dynamic>> _pdfList = [];


  @override
  void initState() {
    super.initState();
    _loadSummaries(); // Fetch stored summaries on page load
  }

  /// Fetches stored summaries from Firestore
  Future<void> _loadSummaries() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('summaries').get();
    setState(() {
      _pdfList = snapshot.docs.map((doc) {
        return {
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

      // Store summary in Firestore
      await FirebaseFirestore.instance.collection('summaries').add({
        'name': pdfName,
        'summary': summary,
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
      appBar: AppBar(title: Text('Note Summarizer'), backgroundColor: Colors.blue,),
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