import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:aceme/theme_provider.dart';
import 'package:aceme/font_size_provider.dart';

class SummarizerPage extends StatefulWidget {
  @override
  _SummarizerPageState createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<SummarizerPage> {
  final String _apiKey = 'KEY-here';
  List<Map<String, dynamic>> _pdfList = [];
  String? _userEmail;
  double _summaryLength = 1.0; // Default to medium summary
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  /// Get the currently logged-in user's email
  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
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

  /// Opens a dialog to enter a name for the PDF and select summary length
  Future<Map<String, dynamic>?> _promptForPdfDetails() async {
    String? pdfName;
    double summaryLength = 1.0; // Default to medium summary

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Enter PDF Name and Upload'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(hintText: 'PDF Name'),
                  ),
                  SizedBox(height: 20),
                  Text('Select Summary Length'),
                  Slider(
                    value: summaryLength,
                    min: 0.0,
                    max: 2.0,
                    divisions: 2,
                    label: summaryLength == 0.0 ? 'Short' : summaryLength == 1.0 ? 'Medium' : 'Long',
                    onChanged: (value) {
                      setState(() {
                        summaryLength = value;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      pdfName = controller.text;
                      Navigator.of(context).pop({
                        'pdfName': pdfName,
                        'summaryLength': summaryLength,
                      });
                    },
                    child: Text('Upload PDF'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (pdfName != null && pdfName!.isNotEmpty) {
      return {
        'pdfName': pdfName,
        'summaryLength': summaryLength,
      };
    }
    return null;
  }

  /// Picks a PDF, extracts text, and sends it for summarization
  Future<void> _pickAndExtractPdf() async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in!')),
      );
      return;
    }

    Map<String, dynamic>? pdfDetails = await _promptForPdfDetails();
    if (pdfDetails != null) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        PDFDoc doc = await PDFDoc.fromFile(file);
        String text = await doc.text;
        _summarizeText(text, pdfDetails['pdfName'], pdfDetails['summaryLength']);
      }
    }
  }

  /// Calls Gemini AI API to summarize text and stores result in Firestore
  Future<void> _summarizeText(String text, String pdfName, double summaryLength) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

    String lengthPrompt;
    if (summaryLength == 0.0) {
      lengthPrompt = 'short';
    } else if (summaryLength == 1.0) {
      lengthPrompt = 'medium';
    } else {
      lengthPrompt = 'long';
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': 'Summarize the following text in a $lengthPrompt summary: $text'}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String summary = (data['candidates']?.isNotEmpty ?? false) &&
              (data['candidates']?[0]['content']['parts']?.isNotEmpty ?? false)
          ? data['candidates']![0]['content']['parts'][0]['text']
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

  /// Displays a dialog with the summary text and a delete button
  void _viewSummary(String summary, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Summary'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSummary(index);
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a summary from Firestore and updates the UI
  Future<void> _deleteSummary(int index) async {
    String summaryName = _pdfList[index]['name'];
    String userEmail = _pdfList[index]['user'] ?? _userEmail!;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('summaries')
        .where('name', isEqualTo: summaryName)
        .where('email', isEqualTo: userEmail)
        .get();

    for (var doc in snapshot.docs) {
      await FirebaseFirestore.instance.collection('summaries').doc(doc.id).delete();
    }

    setState(() {
      _pdfList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Note Summarizer'),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase(); // Store lowercase for case-insensitive search
                });
              },
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black // Ensure black text in dark mode
                    : Colors.black87, // Darker text in light mode for readability
                fontSize: fontSizeProvider.fontSize, // Apply dynamic font size
              ),
              decoration: InputDecoration(
                hintText: 'Search summaries...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                // fillColor: Colors.grey[200], 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), 
                  borderSide: BorderSide.none, 
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: _pdfList.isEmpty
                ? Center(
                    child: Text(
                      'No summaries available',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _pdfList
                        .where((pdf) => pdf['name']
                            .toLowerCase()
                            .contains(_searchQuery)) // Filter by search query
                        .length,
                    itemBuilder: (context, index) {
                      final filteredList = _pdfList
                          .where((pdf) => pdf['name']
                              .toLowerCase()
                              .contains(_searchQuery))
                          .toList(); // Get filtered results
                      return SummaryCard(
                        name: filteredList[index]['name']!,
                        summary: filteredList[index]['summary']!,
                        onDelete: () => _deleteSummary(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndExtractPdf,
        backgroundColor: Colors.blue, // Set the button color to blue
        child: Icon(Icons.add),
      ),
    );
  }
}

class SummaryCard extends StatefulWidget {
  final String name;
  final String summary;
  final VoidCallback onDelete;

  SummaryCard({required this.name, required this.summary, required this.onDelete});

  @override
  _SummaryCardState createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _isExpanded = false;

  void _showFullSummary() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.name),
          content: SingleChildScrollView(
            child: Text(widget.summary),
          ),
          actions: [
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
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeProvider.fontSize),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _isExpanded
                      ? widget.summary
                      : widget.summary.length > 100
                          ? widget.summary.substring(0, 100) + '...'
                          : widget.summary,
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: fontSizeProvider.fontSize),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: _showFullSummary,
                    child: Text(
                      'View',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: fontSizeProvider.fontSize),
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: widget.onDelete,
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: fontSizeProvider.fontSize),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
