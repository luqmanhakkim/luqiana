import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../widget/placeholder_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: AppStrings.expensesTitle,
      subtitle: AppStrings.expensesComingSub,
      icon: Icons.account_balance_wallet_rounded,
    );
  }
}
