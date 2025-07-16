import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/touch_n_go_homepage.dart';

void main() {
  runApp(const EcoPayApp());
}

class EcoPayApp extends StatelessWidget {
  const EcoPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPay - Touch n Go Style',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const TouchNGoHomepage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
