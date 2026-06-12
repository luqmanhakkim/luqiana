import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../widget/placeholder_screen.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: AppStrings.checklistTitle,
      subtitle: AppStrings.checklistComingSub,
      icon: Icons.checklist_rounded,
    );
  }
}
