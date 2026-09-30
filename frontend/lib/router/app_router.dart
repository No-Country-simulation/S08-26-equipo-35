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
import '../features/profile/profile_screen.dart';
import 'session_gate.dart';

/// Nombres de ruta como constantes — evita strings sueltos repetidos
/// por la app ('/home' escrito a mano en 5 lugares distintos).
class AppRoutes {
  AppRoutes._();

  /// Ruta inicial: splash que restaura/valida la sesión (ver SessionGate).
  static const String sessionGate = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String logExpense = '/log-expense';
  static const String groupDetails = '/group-details';
  static const String expenseDetails = '/expense-details';
  static const String balances = '/balances';
  static const String history = '/history';
  static const String markPayment = '/mark-payment';
  static const String profile = '/profile';
}

/// Router sencillo: un mapa de rutas nombradas. El único guard de auth
/// es el `SessionGate` en la ruta inicial ('/'): valida la sesión
/// persistida una vez al arrancar y redirige a onboarding u home.
/// No hay redirección en caliente por 401.
class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> routes = {
    AppRoutes.sessionGate: (context) => const SessionGate(),
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
    AppRoutes.expenseDetails: (context) {
      final expenseId = ModalRoute.of(context)!.settings.arguments as String?;
      return ExpenseDetails(expenseId: expenseId);
    },
    AppRoutes.balances: (context) {
      final groupId =
          ModalRoute.of(context)!.settings.arguments as String?;
      return Balances(groupId: groupId);
    },
    AppRoutes.history: (context) => const History(),
    AppRoutes.markPayment: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      return MarkPayment(args: args is MarkPaymentArgs ? args : null);
    },
    AppRoutes.profile: (context) => const ProfileScreen(),
  };
}
