import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_master/login_page.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
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
                final String firstName = _firstNameController.text;
                final String lastName = _lastNameController.text;
                final String email = _emailController.text;
                final String password = _passwordController.text;

                try {
                  // Create a user with the provided email and password.
                  final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  // Send a verification email to the user.
                  await userCredential.user!.sendEmailVerification();

                  // Update the user's display name with the provided first and last names.
                  await userCredential.user!.updateProfile(
                    displayName: '$firstName $lastName',
                  );

                  // Display a message to the user.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verification email sent. Please check your email to complete registration.'),
                    ),
                  );

                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ));

                } catch (e) {
                  // Handle the specific registration error
                  print('Registration error: $e');

                  // You can provide user-friendly error messages based on the error type
                  if (e is FirebaseAuthException) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? 'An error occurred during registration.'),
                      ),
                    );
                  } else {
                    // Handle other exceptions if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An unexpected error occurred.'),
                      ),
                    );
                  }
                }
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

