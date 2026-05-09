import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import './Splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF50F10);
    const softPurple = Color(0xFF6C5C8F);
    const softBg = Color(0xFFF7F2FC);
    const borderColor = Color(0xFFE2D9F0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F2F8),

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: Colors.black,
          background: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F2F8),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),

        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEDE7F6),
            foregroundColor: const Color(0xFF6C5C8F),
            elevation: 2,
            shadowColor: const Color(0xFF6C5C8F).withOpacity(0.18),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFEDE7F6),
            foregroundColor: const Color(0xFF6C5C8F),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: Color(0x33F50F10),
          selectionHandleColor: primaryColor,
        ),
      ),

      home: splash(),
    );
  }
}