import 'package:flutter/material.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
 return MaterialApp(
  title: 'CIGAL CONSTRUCT',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    primaryColor: Color(0xFFFF6F00), // Orange - construction tone
    scaffoldBackgroundColor: Color(0xFFF5F5F5), // Light grey background
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFFFF6F00),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6F00),
        foregroundColor: Colors.white,
      ),
    ),
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Color(0xFF212121),
          displayColor: Color(0xFF212121),
        ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFFFF6F00),
      brightness: Brightness.light,
    ),
  ),
  home: LoginPage(), // or DashboardPage if already logged in
);

  }
}

