import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
      home: const ResponsiveWrapper(child: TouchNGoHomepage()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only constrain width on web platform
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Container(
            width: 414, // iPhone Pro Max width
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }
    
    // On mobile, return the child as-is
    return child;
  }
}
