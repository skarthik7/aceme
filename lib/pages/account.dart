import 'package:flutter/material.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/login_register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Account extends StatelessWidget {
  final String? email;

  Account({Key? key, this.email}) : super(key: key);

  String _getUsername(String? email) {
    if (email == null) return 'User';
    String name = email.split('@')[0];
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    String? errorMessage;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    errorText: errorMessage,
                  ),
                  obscureText: true,
                ),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  String email = user?.email ?? '';

                  AuthCredential credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentPasswordController.text,
                  );
                  await user?.reauthenticateWithCredential(credential);
                  await user?.updatePassword(newPasswordController.text);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password changed successfully')),
                  );
                  Navigator.of(context).pop();
                } on FirebaseAuthException catch (e) {
                  errorMessage = e.message;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String username = _getUsername(email);

    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Text(
                username[0], // Display first letter of username
                style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            Text(username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email ?? 'No email', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),
            Divider(),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.blue),
              title: Text('Change Password'),
              onTap: () => _changePassword(context),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign out', style: TextStyle(color: Colors.red)),
              onTap: () => signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
