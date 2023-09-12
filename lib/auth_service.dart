import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> registerWithEmailPasswordAndSendVerificationEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send a verification email to the user
      await userCredential.user!.sendEmailVerification();

      return null; // Registration successful, no error message.
    } catch (e) {
      print('Registration error: $e');

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            return 'The email address is already in use.';
          case 'invalid-email':
            return 'Invalid email address.';
          case 'weak-password':
            return 'The password is too weak.';
          default:
            return 'An error occurred during registration.';
        }
      } else {
        return 'An unexpected error occurred.';
      }
    }
  }



  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount == null) return null;

      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
}
