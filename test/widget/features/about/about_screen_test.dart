// Testes unitários — AboutScreen
//
// Cobre: renderização de título, descrição e disclaimer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/features/about/about_screen.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'SunSense',
      packageName: 'uv_exposure_app',
      version: '3.4.0',
      buildNumber: '5',
      buildSignature: '',
    );
  });

  group('AboutScreen', () {
    testWidgets('deve exibir título, nome do app e descrição', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AboutScreen()),
      );

      expect(find.text(AppStrings.aboutTitle), findsOneWidget);
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.aboutDescription), findsOneWidget);
    });

    testWidgets('deve exibir versão dinâmica do aplicativo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AboutScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('${AppStrings.aboutVersion} 3.4.0'), findsOneWidget);
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
