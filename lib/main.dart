import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import './firebase_options.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Detect X',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(shadowColor: Colors.black.withAlpha(128)),
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
            letterSpacing: .5,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            color: Colors.grey.shade900,
            // color: Color(0xFF101010),
            fontWeight: FontWeight.bold,
            // fontFamily: "Intervogue"
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: .6
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: const TextStyle(
            fontSize: 20,
            color: Color(0xFF101010),
            fontWeight: FontWeight.bold,
            height: .5,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            color: Colors.grey.shade900,
            // color: Color(0xFF101010),
            fontWeight: FontWeight.bold,
            height: .5,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade900,
            // color: Color(0xFF101010),
            fontWeight: FontWeight.w600,
            height: 0.5,
          ),
          labelLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          constraints: const BoxConstraints(minHeight: 40),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hintStyle: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.grey.shade600),
          prefixIconColor: Colors.grey,
          filled: true,
          fillColor: Colors.grey.shade100,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
