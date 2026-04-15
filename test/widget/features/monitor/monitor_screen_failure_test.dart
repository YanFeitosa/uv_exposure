/// Testes de falha e resiliência — MonitorScreen
///
/// Cobre: estados de desconexão, erro de conexão, banner de cache (modo degradado).
@Tags(['failure', 'recovery'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';
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

  group('MonitorScreen — falha: desconexão', () {
    testWidgets(
        'deve exibir alerta de desconexão quando stoppedDueToDisconnection',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(stoppedDueToDisconnection: true);
      await tester.pump();

      expect(find.text(AppStrings.monitoringPaused), findsOneWidget);
      expect(find.text(AppStrings.retryReconnect), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('deve exibir texto completo no alerta de stopped',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(stoppedDueToDisconnection: true);
      await tester.pump();

      expect(find.text(AppStrings.monitoringPaused), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(AppStrings.retryReconnect), findsOneWidget);
      expect(
        find.text(AppStrings.noConnectionRetryMessage.replaceAll(
            '{minutes}', '${AppConstants.cacheExpiration.inMinutes}')),
        findsOneWidget,
      );

      await provider.stopMonitoring();
    });

    testWidgets('deve exibir connection error banner com botão retry',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(
        connectionStatus: ConnectionStatus.disconnected,
        connectionError: 'Test error message',
      );
      await tester.pump();

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byTooltip(AppStrings.retryConnection), findsOneWidget);

      await provider.stopMonitoring();
    });
  });

  group('MonitorScreen — falha: modo degradado (cache)', () {
    testWidgets('deve exibir banner de cache quando usingCache',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      provider.setTestState(
        connectionStatus: ConnectionStatus.usingCache,
        disconnectedSince: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      await tester.pump();

      expect(find.text(AppStrings.connectionLostUsingCache), findsOneWidget);
      expect(find.byTooltip(AppStrings.retryConnection), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await provider.stopMonitoring();
    });
  });
}
