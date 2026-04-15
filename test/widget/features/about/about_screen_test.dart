/// Testes unitários — AboutScreen
///
/// Cobre: renderização de título, descrição e disclaimer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/features/about/about_screen.dart';

void main() {
  group('AboutScreen', () {
    testWidgets('deve exibir título, nome do app e descrição', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AboutScreen()),
      );

      expect(find.text(AppStrings.aboutTitle), findsOneWidget);
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.aboutDescription), findsOneWidget);
    });

    testWidgets('deve exibir disclaimer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AboutScreen()),
      );

      await tester.scrollUntilVisible(
        find.text(AppStrings.aboutDisclaimer),
        200,
      );
      expect(find.text(AppStrings.aboutDisclaimer), findsOneWidget);
    });

    testWidgets('deve exibir cards de tecnologia', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AboutScreen()),
      );

      expect(find.textContaining('Flutter'), findsWidgets);
    });
  });
}
