import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mynotes_phone/src/text_editor.dart';
import 'src/splash.dart';
import 'src/home.dart';
import 'src/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

final _router = GoRouter(routes: [
  GoRoute(
      path: '/',
      builder: (context, state) {
        return const Home();
      },
      name: 'splash',
      routes: [
        GoRoute(
            path: 'home',
            builder: (context, state) {
              return const Home();
            }),
        GoRoute(
            path: 'login',
            builder: (context, state) {
              return const Login();
            }),
        GoRoute(
          path: 'document/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return TextEditor(id: id);
          },
        ),
      ])
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
