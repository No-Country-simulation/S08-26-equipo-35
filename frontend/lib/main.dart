import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'design_system/theme/app_theme.dart';
import 'features/auth/data/auth_session.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Restaura token + perfil persistidos antes de construir la app —
  // el SessionGate (ruta inicial) decide a dónde va con eso ya cargado.
  await AuthSession.instance.init();
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
      initialRoute: AppRoutes.sessionGate,
      routes: AppRouter.routes,
    );
  }
}
