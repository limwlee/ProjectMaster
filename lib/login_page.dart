import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_master/forgot_password_page.dart';
import 'package:project_master/main_page.dart';
import 'package:project_master/registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Master'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final String email = _emailController.text;
                final String password = _passwordController.text;

                try {
                  final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  // Check if the user is verified (optional)
                  if (userCredential.user!.emailVerified) {
                    // Navigate to the MenuPage after successful login
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => MainPage(),
                    ));
                  } else {
                    // Handle unverified user (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email not verified. Please verify your email.'),
                      ),
                    );
                  }
                } catch (e) {
                  // Handle login error
                  print('Login error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Login failed. Please check your credentials.'),
                    ),
                  );
                }
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ForgotPasswordPage(),
                    ));
                  },
                  child: Text('Forgot Password?'),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    // Navigate to the registration page
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => RegistrationPage(),
                    ));
                  },
                  child: const Text('Create an Account?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
