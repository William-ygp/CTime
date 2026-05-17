import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_11_2/main.dart';

void main() {
  testWidgets('Smart clock app shows dashboard and navigation', (tester) async {
    await tester.pumpWidget(const SmartClockApp());

    expect(find.text('Hora actual'), findsOneWidget);
    expect(find.text('Acceso rapido'), findsOneWidget);
    expect(find.text('Horario'), findsWidgets);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Configuracion'), findsOneWidget);
    expect(find.text('Arduino + ESP8266'), findsOneWidget);
  });
}
