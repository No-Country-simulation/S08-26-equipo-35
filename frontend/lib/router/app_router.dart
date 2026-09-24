import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/balances/balances.dart';
import '../features/expense_details/expense_details.dart';
import '../features/group_details/group_details.dart';
import '../features/history/history.dart';
import '../features/home/home.dart';
import '../features/log_expense/log_expense.dart';
import '../features/mark_payment/mark_payment.dart';
import '../features/onboarding/onboarding_screen.dart';

/// Nombres de ruta como constantes — evita strings sueltos repetidos
/// por la app ('/home' escrito a mano en 5 lugares distintos).
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String logExpense = '/log-expense';
  static const String groupDetails = '/group-details';
  static const String expenseDetails = '/expense-details';
  static const String balances = '/balances';
  static const String history = '/history';
  static const String markPayment = '/mark-payment';
}

/// Router sencillo: un mapa de rutas nombradas, sin guards de auth ni
/// validaciones — exactamente lo que pide una maqueta. Cuando agregues
/// login real, aquí es donde entraría la lógica de redirección.
class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> routes = {
    AppRoutes.onboarding: (context) => const OnboardingScreen(),
    AppRoutes.login: (context) => const LoginScreen(),
    AppRoutes.home: (context) => const Home(),
    AppRoutes.logExpense: (context) {
      final groupId = ModalRoute.of(context)!.settings.arguments as String;
      return LogExpense(groupId: groupId);
    },
    AppRoutes.groupDetails: (context) {
      final groupId = ModalRoute.of(context)!.settings.arguments as String;
      return GroupDetails(groupId: groupId);
    },
    AppRoutes.expenseDetails: (context) => const ExpenseDetails(),
    AppRoutes.balances: (context) => const Balances(),
    AppRoutes.history: (context) => const History(),
    AppRoutes.markPayment: (context) => const MarkPayment(),
  };
}
