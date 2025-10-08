import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mymoneymentor/core/routes.dart';
import 'package:mymoneymentor/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
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
