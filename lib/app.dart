import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

class DocGenApp extends StatelessWidget {
  const DocGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocGen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
