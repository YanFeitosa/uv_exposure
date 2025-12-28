// This is a basic Flutter widget test for the SunSense app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/providers/history_provider.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen displays app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExposureProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text(AppStrings.appTitle), findsOneWidget);
  });

  testWidgets('HomeScreen displays SPF dropdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExposureProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that SPF dropdown label is displayed
    expect(find.text(AppStrings.spfLabel), findsOneWidget);
  });

  testWidgets('HomeScreen displays Skin Type dropdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExposureProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that Skin Type dropdown label is displayed
    expect(find.text(AppStrings.skinTypeLabel), findsOneWidget);
  });

  testWidgets('Start button is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExposureProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the start button text - should exist in the widget tree
    expect(find.text(AppStrings.startMonitoring), findsOneWidget);
  });
}
