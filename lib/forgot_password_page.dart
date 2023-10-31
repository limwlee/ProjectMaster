import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_master/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  String _resetPasswordError = '';

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();

    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Display a success message and navigate to login page or another screen.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent. Please check your email to reset your password.'),
        ),
      );
      Navigator.of(context).pop(MaterialPageRoute(
        builder: (context) => LoginPage(),
      ));
    } catch (e) {
      setState(() {
        _resetPasswordError = e.toString();
      });

      // Display an error message to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset failed. $_resetPasswordError'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Forgot Password'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedTextKit(
              animatedTexts: [
                WavyAnimatedText(
                    'Project Master',
                    textStyle: GoogleFonts.lobster(
                        textStyle: TextStyle(
                          color: Colors.blue,
                          fontSize: 40,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        )
                    )
                )
              ],
              repeatForever: true,
            ),
            Divider(),
            Text('We will send an email for you to reset your password',style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),),
            Divider(),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Reset Password'),
            ),
            if (_resetPasswordError.isNotEmpty)
              Text(
                _resetPasswordError,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
