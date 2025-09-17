import 'package:flutter/material.dart';
import 'package:mymoneymentor/core/routes.dart';

void main() {
  runApp(const MyApp());
}

// MyApp as StatelessWidget, only wraps MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      routes: Routes.getRoutes(),
    );
  }
}