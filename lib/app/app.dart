import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../constants/app_strings.dart';
import '../features/home/home_screen.dart';

class LuqianaApp extends StatelessWidget {
  const LuqianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
