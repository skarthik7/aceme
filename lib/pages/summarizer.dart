import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SummarizerPage extends StatefulWidget {
  @override
  _SummarizerPageState createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<SummarizerPage> {
  String _summary = '';
  final String _apiKey = 'AIzaSyDEit47_ToU42NqvYTk_VN1jg5rVegRllo';
  List<Map<String, String>> _pdfList = [];

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
                onPressed: () async {
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

  Future<void> _summarizeText(String text, String pdfName) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';
    int retryCount = 0;
    const int maxRetries = 3;
    const int initialDelay = 2; // in seconds

    while (retryCount < maxRetries) {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'Summarize the following text.: $text'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data: $data'); // Debugging line to print the response data
        if (data != null && data['candidates'] != null && data['candidates'].isNotEmpty && data['candidates'][0]['content'] != null && data['candidates'][0]['content']['parts'] != null && data['candidates'][0]['content']['parts'].isNotEmpty) {
          setState(() {
            _pdfList.add({'name': pdfName, 'summary': data['candidates'][0]['content']['parts'][0]['text']});
          });
        } else {
          setState(() {
            _pdfList.add({'name': pdfName, 'summary': 'Failed to summarize text: Invalid response format'});
          });
        }
        return;
      } else if (response.statusCode == 429) {
        // Too many requests, wait and retry
        retryCount++;
        await Future.delayed(Duration(seconds: initialDelay * retryCount));
      } else {
        setState(() {
          _pdfList.add({'name': pdfName, 'summary': 'Failed to summarize text: ${response.reasonPhrase}'});
        });
        return;
      }
    }

    setState(() {
      _pdfList.add({'name': pdfName, 'summary': 'Failed to summarize text: Too many requests'});
    });
  }

  void _viewSummary(String summary) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Summary'),
          content: SingleChildScrollView(
            child: Text(summary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
      appBar: AppBar(
        title: Text('Your notes summarized!'),
      ),
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