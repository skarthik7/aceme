import 'package:flutter/material.dart';
import 'package:aceme/auth.dart';
import 'package:aceme/pages/login_register_page.dart'; // Import the login_register_page
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class Account extends StatelessWidget {
  final String? email;

  Account({Key? key, this.email}) : super(key: key);

  String _getUsername(String? email) {
    if (email == null) return 'User';
    return email.split('@')[0];
  }

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to login_register_page after sign out
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    String? errorMessage;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  String email = user?.email ?? '';

                  // Reauthenticate the user
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentPasswordController.text,
                  );
                  await user?.reauthenticateWithCredential(credential);

                  // Update the password
                  await user?.updatePassword(newPasswordController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password changed successfully')),
                  );
                  Navigator.of(context).pop();
                } on FirebaseAuthException catch (e) {
                  errorMessage = e.message;
                  // Update the state to show the error message
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getUsername(email)), // Show username instead of "Account"
      ),
      body: Center(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email),
              title: Text(email ?? 'No email'),
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () {
                _changePassword(context); // Show change password dialog
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                signOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}