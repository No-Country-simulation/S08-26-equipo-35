import 'package:flutter/material.dart';
import 'package:splitflow/design_system/theme/app_theme.dart';
import 'package:splitflow/features/onboarding/onboarding_screen.dart';

void main() {
  runApp(const MainApp());
}

void nextapp() {}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: OnboardingScreen())),
    );
  }
}
