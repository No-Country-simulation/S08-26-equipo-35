import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_tokens.dart';
import '../design_system/tokens/app_typography.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_session.dart';
import 'app_router.dart';

/// Ruta inicial `/`: decide a dónde arranca la app según la sesión
/// persistida (ver `AuthSession.init()` en `main.dart`).
///
/// - Sin token → onboarding (login/registro).
/// - Con token → lo valida contra `GET /me`:
///   - OK → home (auto-login).
///   - 401/403 → token vencido/inválido: se limpia la sesión → onboarding.
///   - Error de red / cold start (status 0, 503…) → home con el perfil
///     cacheado; Home ya maneja sus propios errores de carga.
///
/// Es la única validación de token: no hay 401 en caliente (decisión de
/// alcance — `ApiClient` no redirige).
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  @override
  void initState() {
    super.initState();
    // Se pospone al primer frame: llamar _resolve() (y por ende
    // Navigator.pushReplacementNamed) de forma síncrona desde initState
    // ocurre DURANTE el build y Flutter lanza "setState() or
    // markNeedsBuild() called during build", la navegación falla y la app
    // queda eternamente en este splash.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (!AuthSession.instance.isAuthenticated) {
      _go(AppRoutes.onboarding);
      return;
    }

    try {
      await AuthRepository.instance.fetchProfile();
      _go(AppRoutes.home);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await AuthSession.instance.clear();
        _go(AppRoutes.onboarding);
      } else {
        // Errores de red/cold start: seguimos con el perfil cacheado.
        _go(AppRoutes.home);
      }
    } catch (_) {
      _go(AppRoutes.home);
    }
  }

  void _go(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppMd3Colors.surfaceContainerLowest,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Center(
                child: Text(
                  'S',
                  style: AppTypography.headlineLg(color: AppMd3Colors.primaryContainer),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'SplitFlow',
              style: AppTypography.headlineLg(color: AppSemanticColors.slate900),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
