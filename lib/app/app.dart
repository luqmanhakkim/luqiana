import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../config/theme.dart';
import '../constants/app_strings.dart';
import '../core/providers/theme_provider.dart';
import '../features/home/home_screen.dart';

class LuqianaApp extends ConsumerWidget {
  const LuqianaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = ref.watch(themeColorProvider);
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeColor),
      home: const HomeScreen(),
    );
  }
}
