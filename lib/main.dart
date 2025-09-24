import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QRCodeApp());
}

class QRCodeApp extends StatelessWidget {
  const QRCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner & Generator',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
          background: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          error: Colors.red,
          onError: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFFE5E5E5), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E5E5),
          thickness: 1,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Colors.black,
          background: Colors.black,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          error: Colors.red,
          onError: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardTheme: const CardThemeData(
          color: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF333333), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333)),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333)),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF333333),
          thickness: 1,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}