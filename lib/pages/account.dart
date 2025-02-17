import 'package:flutter/material.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/login_register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aceme/theme_provider.dart';
import 'package:aceme/font_size_provider.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Account extends StatefulWidget {
  final String? email;

  Account({Key? key, this.email}) : super(key: key);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  File? _image;

  String _getUsername(String? email) {
    if (email == null) return 'User';
    String name = email.split('@')[0];
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> signOut(BuildContext context) async {
  try {
    await Auth().signOut();

    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });
  } catch (e) {
    print('Error signing out: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    String username = _getUsername(widget.email);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? Text(
                          username[0],
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize, // Apply dynamic font size
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 15, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(username, style: TextStyle(fontSize: fontSizeProvider.fontSize, fontWeight: FontWeight.bold)),
            Text(widget.email ?? 'No email', style: TextStyle(color: Colors.grey, fontSize: fontSizeProvider.fontSize)),
            SizedBox(height: 20),
            Divider(),

            // Font Size Slider
            ListTile(
              title: Text("Font Size", style: TextStyle(fontSize: fontSizeProvider.fontSize)),
              subtitle: Slider(
                value: fontSizeProvider.fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: fontSizeProvider.fontSize.toString(),
                onChanged: (value) {
                  fontSizeProvider.setFontSize(value);
                },
              ),
              leading: Icon(Icons.text_fields, color: Colors.blue),
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.lock, color: Colors.blue),
              title: Text('Change Password', style: TextStyle(fontSize: fontSizeProvider.fontSize)),
              onTap: () {},
            ),
            Divider(),

            SwitchListTile(
              title: Text('Dark Mode', style: TextStyle(fontSize: fontSizeProvider.fontSize)),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
              secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign out', style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.red)),
              onTap: () => signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}