import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/design_system/components/ui/buttons/app_text_action.dart';
import 'package:splitflow/design_system/tokens/app_colors.dart';

void main() {
  /// Pinta [child] y devuelve el color con el que quedó su label.
  Future<Color> labelColor(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
    return tester.widget<Text>(find.byType(Text)).style!.color!;
  }

  testWidgets('por defecto es slate (acción neutra)', (tester) async {
    final color = await labelColor(
      tester,
      AppTextAction(label: 'Cancel', onPressed: () {}),
    );

    expect(color, AppSemanticColors.slate600);
  });

  testWidgets('emphasized pinta índigo', (tester) async {
    final color = await labelColor(
      tester,
      AppTextAction(label: 'Save', onPressed: () {}, emphasized: true),
    );

    expect(color, AppMd3Colors.primaryContainer);
  });

  testWidgets('destructive pinta rojo', (tester) async {
    final color = await labelColor(
      tester,
      AppTextAction(label: 'Reject', onPressed: () {}, destructive: true),
    );

    expect(color, AppSemanticColors.negativeText);
  });

  testWidgets('destructive tiene prioridad sobre emphasized', (tester) async {
    final color = await labelColor(
      tester,
      AppTextAction(
        label: 'Reject',
        onPressed: () {},
        emphasized: true,
        destructive: true,
      ),
    );

    expect(color, AppSemanticColors.negativeText);
  });

  testWidgets('onPressed null deshabilita el tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextAction(label: 'Reject', onPressed: null, destructive: true),
        ),
      ),
    );

    await tester.tap(find.text('Reject'));
    expect(tapped, isFalse);
  });

  testWidgets('onPressed se dispara al tocar', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextAction(
            label: 'Reject',
            onPressed: () => tapped = true,
            destructive: true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reject'));
    expect(tapped, isTrue);
  });
}
