import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      } else {
        print(e.code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 250),
        const Text('MyNotes',
            style: TextStyle(
                fontSize: 75,
                color: Colors.black,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 200),
        Container(
            width: 300,
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            )),
        Container(
            width: 300,
            child: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            )),
        const SizedBox(height: 100),
        Container(
            width: 300,
            child: ElevatedButton(
              onPressed: _signIn,
              child: const Text('Sign In'),
            )),
      ],
    )));
  }
}
