/// Testes unitários — InfoBox
///
/// Cobre: renderização de título, info e subtitle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/shared/widgets/info_box.dart';

void main() {
  group('InfoBox', () {
    testWidgets('deve exibir título e info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBox(
              title: 'Tempo',
              info: '01:30:00',
              infoColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Tempo'), findsOneWidget);
      expect(find.text('01:30:00'), findsOneWidget);
    });

    testWidgets('deve exibir subtitle quando fornecido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBox(
              title: 'UV',
              info: '7.5',
              infoColor: Colors.red,
              subtitle: 'Muito Alto',
            ),
          ),
        ),
      );

      expect(find.text('UV'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('Muito Alto'), findsOneWidget);
    });

    testWidgets('não deve exibir subtitle quando null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBox(
              title: 'Info',
              info: '42',
              infoColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Info'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });
}
