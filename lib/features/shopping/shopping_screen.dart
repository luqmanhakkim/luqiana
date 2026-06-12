import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../widget/placeholder_screen.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: AppStrings.shoppingTitle,
      subtitle: AppStrings.shoppingComingSub,
      icon: Icons.shopping_bag_rounded,
    );
  }
}
