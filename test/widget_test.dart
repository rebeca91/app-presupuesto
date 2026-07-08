import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_presupuesto/main.dart';

void main() {
  testWidgets('muestra la pantalla principal del presupuesto', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'ingresoMensual': 1000.0});

    await tester.pumpWidget(const BudgetApp());
    await tester.pump();

    expect(find.text('Mi Presupuesto'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
  });
}
