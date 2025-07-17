import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'screens/touch_n_go_homepage.dart';

Future<void> main() async {
  await dotenv.load(); // Load your .env file before app starts
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TouchNGoHomepage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
