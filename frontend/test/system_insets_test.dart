import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/design_system/navigations/app_bottom_nav_bar.dart';
import 'package:splitflow/design_system/navigations/app_top_bar.dart';

/// Tests de los insets de sistema (status bar arriba, barra de gestos abajo).
///
/// Regresión que cubren: con `targetSdk >= 35` Android fuerza edge-to-edge. Si
/// estas barras y los botones flotantes no suman `MediaQuery.padding`, el
/// contenido arranca en `y=0` / termina en el borde y el reloj o la barra de
/// navegación quedan encima. Falló en dispositivo y el analyze no lo detecta,
/// así que queda fijado acá.
void main() {
  /// Envuelve como lo haría un dispositivo con status bar y barra de gestos.
  Widget withInsets(Widget child, {double top = 0, double bottom = 0}) {
    return MediaQuery(
      data: MediaQueryData(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        viewPadding: EdgeInsets.only(top: top, bottom: bottom),
      ),
      child: child,
    );
  }

  const nav = AppBottomNavBar(
    items: [
      AppBottomNavItem(icon: Icons.groups, label: 'Grupos'),
      AppBottomNavItem(icon: Icons.person, label: 'Perfil'),
    ],
    currentIndex: 0,
    onTap: _noop,
  );

  group('AppTopBar', () {
    testWidgets('suma el inset de status bar a su alto', (tester) async {
      await tester.pumpWidget(withInsets(
        MaterialApp(
          home: Scaffold(appBar: const AppTopBar(title: 'Inicio')),
        ),
        top: 24,
      ));

      expect(tester.getSize(find.byType(AppTopBar)).height, 80);
    });

    testWidgets('sin inset queda en el alto de contenido', (tester) async {
      await tester.pumpWidget(withInsets(
        const MaterialApp(
          home: Scaffold(appBar: AppTopBar(title: 'Inicio')),
        ),
      ));

      expect(tester.getSize(find.byType(AppTopBar)).height, 56);
    });

    testWidgets('preferredSize NO incluye el inset', (tester) async {
      // A propósito: `Scaffold` mide el alto renderizado del hijo y su
      // `_appBarMaxHeight` ya suma el padding por su cuenta. Si el inset
      // estuviera en `preferredSize` se contaría dos veces.
      expect(const AppTopBar(title: 'x').preferredSize.height, 56);
    });

    testWidgets('el fondo por defecto es opaco', (tester) async {
      await tester.pumpWidget(withInsets(
        const MaterialApp(
          home: Scaffold(appBar: AppTopBar(title: 'Inicio')),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppTopBar),
          matching: find.byType(Container),
        ),
      );
      expect(container.color?.a ?? 0, greaterThan(0));
    });

    testWidgets('backgroundColor explicito se respeta (cabecera a sangre)',
        (tester) async {
      await tester.pumpWidget(withInsets(
        const MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Inicio',
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppTopBar),
          matching: find.byType(Container),
        ),
      );
      expect(container.color, Colors.transparent);
    });

    testWidgets('la banda de contenido sigue midiendo 56 con inset',
        (tester) async {
      // El inset se come alto de la caja, no estira la banda de contenido: el
      // `Row` queda con sus 56px y el título se sigue centrando en esa banda.
      // Si el inset se sumara por otro lado, el contenido se separaría del
      // reloj.
      await tester.pumpWidget(withInsets(
        const MaterialApp(
          home: Scaffold(appBar: AppTopBar(title: 'Inicio')),
        ),
        top: 24,
      ));
      final conInset = tester.getRect(find.text('Inicio')).center.dy;

      await tester.pumpWidget(withInsets(
        const MaterialApp(
          home: Scaffold(appBar: AppTopBar(title: 'Inicio')),
        ),
      ));
      final sinInset = tester.getRect(find.text('Inicio')).center.dy;

      // El titulo baja exactamente lo que sube el inset, ni un pixel mas.
      expect(conInset - sinInset, 24);
    });
  });

  group('Scaffold consume el padding superior del body', () {
    // Estos tests fijan por qué Group Details lee los insets **por encima**
    // del Scaffold. Regresión real: leerlos adentro del body daba 0, la
    // portada quedaba 56px más corta y el botón de ajustes caía bajo el reloj.
    testWidgets('el body pierde padding.top Y viewPadding.top', (tester) async {
      double? paddingTop;
      double? viewPaddingTop;

      await tester.pumpWidget(withInsets(
        MaterialApp(
          home: Scaffold(
            appBar: const AppTopBar(title: 'Inicio'),
            body: _Probe(
              onProbe: (context) {
                paddingTop = MediaQuery.paddingOf(context).top;
                viewPaddingTop = MediaQuery.viewPaddingOf(context).top;
              },
            ),
          ),
        ),
        top: 24,
      ));

      expect(paddingTop, 0,
          reason: 'Scaffold quita el padding superior del body si hay appBar');
      // Contra-intuitivo: `viewPadding` tampoco sirve adentro del body.
      // `MediaQueryData.removePadding` descuenta el padding removido del
      // viewPadding, así que 24 - 24 = 0. Por eso `viewPaddingOf` no era la
      // solución y el inset hay que leerlo del context de la pantalla.
      expect(viewPaddingTop, 0,
          reason: 'removePadding descuenta tambien de viewPadding');
    });

    testWidgets('por encima del Scaffold el inset sigue intacto',
        (tester) async {
      double? paddingTop;

      await tester.pumpWidget(withInsets(
        Builder(
          builder: (context) {
            paddingTop = MediaQuery.paddingOf(context).top;
            // Montamos el Scaffold igual, para que el árbol sea realista.
            return const MaterialApp(
              home: Scaffold(
                appBar: AppTopBar(title: 'Inicio'),
                body: SizedBox.shrink(),
              ),
            );
          },
        ),
        top: 24,
      ));

      expect(paddingTop, 24);
    });

    testWidgets('el body conserva padding.bottom si no hay bottomNavigationBar',
        (tester) async {
      double? paddingBottom;

      await tester.pumpWidget(withInsets(
        MaterialApp(
          home: Scaffold(
            appBar: const AppTopBar(title: 'Inicio'),
            body: _Probe(
              onProbe: (context) {
                paddingBottom = MediaQuery.paddingOf(context).bottom;
              },
            ),
          ),
        ),
        bottom: 34,
      ));

      // Por eso el boton "Agregar gasto" de Group Details necesita sumar el
      // inset: el body llega hasta el borde inferior de la pantalla.
      expect(paddingBottom, 34);
    });

    testWidgets('con bottomNavigationBar el body pierde padding.bottom',
        (tester) async {
      double? paddingBottom;

      await tester.pumpWidget(withInsets(
        MaterialApp(
          home: Scaffold(
            appBar: const AppTopBar(title: 'Inicio'),
            bottomNavigationBar: nav,
            body: _Probe(
              onProbe: (context) {
                paddingBottom = MediaQuery.paddingOf(context).bottom;
              },
            ),
          ),
        ),
        bottom: 34,
      ));

      // Y por eso el boton equivalente de home.dart NO lleva inset.
      expect(paddingBottom, 0);
    });
  });

  group('Boton flotante sobre el body', () {
    // Reproduce el `Positioned` de Group Details: el inset se lee desde
    // adentro del body, que es donde vive el Stack.
    Future<void> pumpFab(WidgetTester tester, {double bottom = 0}) {
      return tester.pumpWidget(withInsets(
        MaterialApp(
          home: Scaffold(
            appBar: const AppTopBar(title: 'Inicio'),
            body: const _Fab(),
          ),
        ),
        bottom: bottom,
      ));
    }

    testWidgets('queda sobre la barra de navegacion, no debajo',
        (tester) async {
      await pumpFab(tester, bottom: 34);

      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final fab = tester.getRect(find.byKey(const Key('fab')));

      // 16 de margen + 34 de inset = el borde inferior del boton queda a 50px
      // del borde de la pantalla, o sea por encima de la barra de 34px.
      expect(screenHeight - fab.bottom, 50);
    });

    testWidgets('sin inset queda a 16px del borde', (tester) async {
      await pumpFab(tester);

      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final fab = tester.getRect(find.byKey(const Key('fab')));

      expect(screenHeight - fab.bottom, 16);
    });
  });

  group('AppBottomNavBar', () {
    testWidgets('suma el inset inferior de la barra de gestos',
        (tester) async {
      await tester.pumpWidget(withInsets(
        const MaterialApp(home: Scaffold(body: SizedBox(), bottomNavigationBar: nav)),
        bottom: 34,
      ));
      final conInset = tester.getSize(find.byType(AppBottomNavBar)).height;

      await tester.pumpWidget(withInsets(
        const MaterialApp(home: Scaffold(body: SizedBox(), bottomNavigationBar: nav)),
      ));
      final sinInset = tester.getSize(find.byType(AppBottomNavBar)).height;

      expect(conInset - sinInset, 34);
    });
  });
}

void _noop(int _) {}

/// Lee los insets del contexto en que queda montado y avisa.
class _Probe extends StatelessWidget {
  const _Probe({required this.onProbe});

  final void Function(BuildContext context) onProbe;

  @override
  Widget build(BuildContext context) {
    onProbe(context);
    return const SizedBox.shrink();
  }
}

/// Copia del `Positioned` de "Agregar gasto" en Group Details.
class _Fab extends StatelessWidget {
  const _Fab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 0,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: const SizedBox(width: 100, height: 48, key: Key('fab')),
        ),
      ],
    );
  }
}
