import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';

/// Shown for routes a team member has not added yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This part of ParkPin is still being built.\n($routeName)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
