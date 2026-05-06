// Testes de integração — HomeScreen
//
// Cobre: descartar sessão+limpar dados, restaurar sessão+navegar,
// iniciar monitoramento completo com seleções.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/providers/history_provider.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/core/services/notification_service.dart';
import 'package:uv_exposure_app/features/home/home_screen.dart';
import 'package:uv_exposure_app/features/settings/settings_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel audioChannel = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  setUp(() async {
    StorageService.resetForTest();
    NotificationService.initForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildHomeScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExposureProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/history': (_) => const Scaffold(body: Text('History')),
          '/about': (_) => const Scaffold(body: Text('About')),
          '/monitor': (_) => const Scaffold(body: Text(AppStrings.elapsedTime)),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }

  group('HomeScreen — integração: descartar sessão', () {
    testWidgets('descartar deve fechar diálogo e limpar dados', (tester) async {
      await StorageService.saveLastSession(
        spf: 30,
        skinType: 'Tipo II - Clara',
        accumulatedExposure: 25.5,
        secondsElapsed: 300,
      );

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Sessão Anterior Encontrada'), findsOneWidget);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.text('Sessão Anterior Encontrada'), findsNothing);

      final session = await StorageService.getLastSession();
      expect(session, isNull);
    });
  });

  group('HomeScreen — integração: restaurar sessão', () {
    testWidgets('restaurar deve navegar para MonitorScreen', (tester) async {
      await StorageService.saveLastSession(
        spf: 50,
        skinType: 'Tipo II - Clara',
        accumulatedExposure: 10.0,
        secondsElapsed: 120,
      );

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Sessão Anterior Encontrada'), findsOneWidget);

      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.elapsedTime), findsOneWidget);
    });
  });

  group('HomeScreen — integração: iniciar monitoramento', () {
    testWidgets('deve navegar para MonitorScreen ao selecionar e iniciar',
        (tester) async {
      await StorageService.setDemoMode(true);

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tipo 0 - Demo').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('${AppStrings.spfPrefix} 30').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.start));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(AppStrings.elapsedTime), findsOneWidget);
    });
  });

  group('HomeScreen — integração: navegação', () {
    testWidgets('ícone settings deve navegar para SettingsScreen',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('ícone history deve navegar para /history', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('ícone about deve navegar para /about', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byTooltip(AppStrings.about));
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);
    });
  });
}
