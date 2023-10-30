
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_master/forgot_password_page.dart';
import 'package:project_master/main_page.dart';
import 'package:project_master/registration_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String _loginError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Project Master'),
      // ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                SizedBox(height: 10,),
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      'Your Project Success, Our Mission with Project Master',
                      textStyle: GoogleFonts.lobster(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  repeatForever: true,
                  pause: const Duration(milliseconds: 2000),
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
                SizedBox(height: 10,),
                Divider(),
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
                      final UserCredential userCredential = await FirebaseAuth
                          .instance
                          .signInWithEmailAndPassword(
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
                            content: Text(
                                'Email not verified. Please verify your email.'),
                          ),
                        );
                      }
                    } catch (e) {
                      // Handle login error
                      print('Login error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Login failed. Please check your credentials.'),
                        ),
                      );
                    }
                  },
                  child: Text('Login'),
                ),
                SizedBox(height: 5),
                Text("OR"),
                SizedBox(height: 5),
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Icon(Icons.login),
                  label: Text('Sign In with Google'),
                ),
                SizedBox(height: 30),
                Divider(),
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
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        // User canceled the Google Sign-In process
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      await _googleSignIn.signOut();

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MainPage(),
        ));
      } else {
        setState(() {
          _loginError = 'Google Sign-In failed. Please try again.';
        });
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      setState(() {
        _loginError = 'Google Sign-In failed. Please try again.';
      });
    }
  }
}
