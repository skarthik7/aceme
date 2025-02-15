import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMsg = "";
  bool isLogin = true;
  bool _isPasswordVisible = false; 
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  String _getCustomErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'Invalid email address or password. Please re-enter your login info.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      print("Firebase Error Code: ${e.code}");
      setState(() {
        errorMsg = _getCustomErrorMessage(e.code); // 🔹 Map error codes
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      print("Firebase Error Code: ${e.code}");
      setState(() {
        errorMsg = _getCustomErrorMessage(e.code); // 🔹 Map error codes
      });
    }
  }

  Widget _title() {
    return const Text('Ace Me');
  }

  Widget _entryField(String title, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _errorMessage() {
    return Text(
      errorMsg == '' ? '' : errorMsg!,
      style: TextStyle(color: Colors.red), 
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      child: Text(isLogin ? 'Login' : 'Register'),
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
        });
      },
      child: Text(isLogin ? 'Need an account? Register' : 'Already have an account? Login'),
    );
  }

  Widget _socialButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: color, size: 40),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          padding: const EdgeInsets.all(21),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                  width: 140, // image is a square for perfect circle
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 50), // Space between image and fields
              _entryField('Email', _controllerEmail),
              SizedBox(height: 10), // Space between fields
              _entryField('Password', _controllerPassword, isPassword: true), 
              SizedBox(height: 10), // Space between fields and error message
              _errorMessage(),
              SizedBox(height: 10), // Space between error message and button
              _submitButton(),
              _loginOrRegisterButton(),
              SizedBox(height: 10), // Space between buttons
              Text('Or continue with'),
              SizedBox(height: 10), // Space between text and social buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  SizedBox(width: 10), // Space between social buttons
                  _socialButton(Icons.apple, Colors.black, () {
                    // Handle Apple sign-in
                  }),
                  SizedBox(width: 10), // Space between social buttons
                  _socialButton(Icons.facebook, Colors.blue, () {
                    // Handle Facebook sign-in
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}