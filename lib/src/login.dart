import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  Future<void> _signIn() async {
    final url = Uri.parse(
        'http://10.0.2.2:5000/api/users/getByEmail/phone'); 
    try {
      final response = await http.post(
        url,
        body: {
          'email': _emailController.text,
        },
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);

        if (user['password'] == _passwordController.text) {
          await secureStorage.write(key: 'token', value: user['token']);
          await secureStorage.write(key: 'email', value: user['email']);
          await secureStorage.write(key: 'username', value: user['username']);
          GoRouter.of(context).go('/home');
        } else {
          print('Invalid password');
        }
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Center(
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
    ))));
  }
}
