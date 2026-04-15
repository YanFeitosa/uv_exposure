/// Testes de borda — MonitorScreen
///
/// Cobre: alarme ativo, níveis UV (baixo/moderado/muito alto/extremo),
/// gap dialog (normal e exceeded max).
@Tags(['edge'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/features/monitor/monitor_screen.dart';

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
    SharedPreferences.setMockInitialValues({
      'notification_permission_asked': true,
    });
    await StorageService.init();
  });

  Widget buildMonitorScreen(ExposureProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: MonitorScreen()),
    );
  }

  group('MonitorScreen — borda: alarme', () {
    testWidgets('deve exibir botão parar alarme quando alarme ativo',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(alarmActive: true);
      await tester.pump();

      expect(find.text(AppStrings.stopAlarm), findsOneWidget);
      await provider.stopMonitoring();
    });
  });

  group('MonitorScreen — borda: níveis UV', () {
    testWidgets('UV baixo (1.0)', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(currentUVIndex: 1.0);
      await tester.pump();
      expect(find.text(AppStrings.uvLow), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('UV moderado (4.0)', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(currentUVIndex: 4.0);
      await tester.pump();
      expect(find.text(AppStrings.uvModerate), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('UV muito alto (9.5)', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(currentUVIndex: 9.5);
      await tester.pump();
      expect(find.text(AppStrings.uvVeryHigh), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('UV extremo (12.0)', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(currentUVIndex: 12.0);
      await tester.pump();
      expect(find.text(AppStrings.uvExtreme), findsOneWidget);

      await provider.stopMonitoring();
    });
  });

  group('MonitorScreen — borda: gap dialog', () {
    testWidgets('deve exibir diálogo de gap quando gapDetected',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(
        gapDetected: true,
        gapDismissed: false,
        lastGapDurationSeconds: 45,
        lastGapCompensatedSeconds: 45,
        gapExceededMax: false,
        gapUVIndex: 6.5,
      );
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.gapDialogTitle), findsOneWidget);
      expect(find.text(AppStrings.gapDismiss), findsOneWidget);

      await tester.tap(find.text(AppStrings.gapDismiss));
      await tester.pumpAndSettle();
      expect(provider.gapDismissed, isTrue);

      await provider.stopMonitoring();
    });

    testWidgets('deve exibir diálogo de gap com exceeded max',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(
        gapDetected: true,
        gapDismissed: false,
        lastGapDurationSeconds: 2400,
        lastGapCompensatedSeconds: 1200,
        gapExceededMax: true,
        gapUVIndex: 8.0,
      );
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.gapDialogTitle), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);

      await tester.tap(find.text(AppStrings.gapDismiss));
      await tester.pumpAndSettle();

      await provider.stopMonitoring();
    });
  });
}
