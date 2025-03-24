import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare_app/screens/home.dart';

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      return null; // Success
    } catch (e) {
      return "Invalid email or password"; // Failure message
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: data.name!,
            password: data.password!,
          );

      // Store user details in Firestore
      await _firestore.collection('nurses').doc(userCredential.user!.uid).set({
        'email': data.name,
        'role': 'nurse',
      });

      return null; // Success
    } catch (e) {
      return "Signup failed. Try again!";
    }
  }

  Future<String?> _recoverPassword(String name) async {
    try {
      await _auth.sendPasswordResetEmail(email: name);
      return null; // Success
    } catch (e) {
      return "Invalid email";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Nurse Reminder',
      onLogin: _authUser,
      onSignup: _signupUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      },
      theme: LoginTheme(
        primaryColor: Colors.blue,
        accentColor: Colors.white,
        errorColor: Colors.red,
        cardTheme: CardTheme(color: Colors.white, elevation: 8),
      ),
    );
  }
}
