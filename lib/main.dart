import 'package:flutter/material.dart';
import 'package:ohanas_app/screens/homePage.dart';
import 'package:ohanas_app/screens/ohanas_login.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OhanasLogin(),
    );
  }
}
