import 'package:flutter/material.dart';
import '../features/home/home.dart';
import '../features/onboarding/onboarding_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/';
  static const String home = '/home';
}

class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> routes = {
    AppRoutes.onboarding: (context) => const OnboardingScreen(),
    AppRoutes.home: (context) => const Home(),
  };
}
