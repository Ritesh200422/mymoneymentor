import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mymoneymentor/core/routes.dart';
import 'package:mymoneymentor/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "MyMoneyMentor",
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,

        // ✅ Updated textTheme with font fallback
        textTheme: GoogleFonts.notoSansTextTheme(baseTheme.textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamilyFallback: ['NotoEmoji', 'NotoSansSymbols'],
        ),

        colorScheme: baseTheme.colorScheme.copyWith(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: Routes.login,
      routes: Routes.getRoutes(),
    );
  }
}
