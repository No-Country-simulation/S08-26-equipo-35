import 'package:flutter/material.dart';
import 'design_system/theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  runApp(const SplitFlowApp());
}

class SplitFlowApp extends StatelessWidget {
  const SplitFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.onboarding,
      routes: AppRouter.routes,
    );
  }
}
