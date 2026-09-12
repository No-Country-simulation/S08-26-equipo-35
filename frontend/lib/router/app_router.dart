import 'package:flutter/material.dart';
import '../features/expense_details/expense_details.dart';
import '../features/group_details/group_details.dart';
import '../features/home/home.dart';
import '../features/log_expense/log_expense.dart';
import '../features/onboarding/onboarding_screen.dart';

/// Nombres de ruta como constantes — evita strings sueltos repetidos
/// por la app ('/home' escrito a mano en 5 lugares distintos).
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/';
  static const String home = '/home';
  static const String logExpense = '/log-expense';
  static const String groupDetails = '/group-details';
  static const String expenseDetails = '/expense-details';
}

/// Router sencillo: un mapa de rutas nombradas, sin guards de auth ni
/// validaciones — exactamente lo que pide una maqueta. Cuando agregues
/// login real, aquí es donde entraría la lógica de redirección.
class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> routes = {
    AppRoutes.onboarding: (context) => const OnboardingScreen(),
    AppRoutes.home: (context) => const Home(),
    AppRoutes.logExpense: (context) => LogExpense(),
    AppRoutes.groupDetails: (context) => const GroupDetails(),
    AppRoutes.expenseDetails: (context) => const ExpenseDetails(),
  };
}
