/// Testes de borda — ExposureProvider
///
/// Cobre: pausa e retomada, estados de setTestState (cache threshold, disconnectedSince).
@Tags(['edge'])
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeUri());

    const MethodChannel audioChannel = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (MethodCall methodCall) async {
      return null;
    });

    const MethodChannel notificationsChannel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel,
            (MethodCall methodCall) async {
      return null;
    });
  });

  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    mockClient = MockHttpClient();
    UVDataService.setHttpClient(mockClient);
    UVDataService.clearCache();
    UVDataService.resetUrlPreference();
  });

  tearDown(() {
    UVDataService.restoreHttpClient();
  });

  group('ExposureProvider — borda: pausa e retomada', () {
    test('pauseMonitoring deve parar o timer mas manter isMonitoring', () {
      fakeAsync((async) {
        final provider = ExposureProvider();
        provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
        provider.setDemoMode(true);

        provider.startMonitoring();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        provider.pauseMonitoring();
        expect(provider.isMonitoring, isTrue);

        final secondsAfterPause = provider.secondsElapsed;
        async.elapse(const Duration(seconds: 2));
        expect(provider.secondsElapsed, equals(secondsAfterPause));

        provider.stopMonitoring();
        async.flushMicrotasks();
        provider.dispose();
      });
    });

    test('resumeMonitoring deve retomar acumulação', () {
      fakeAsync((async) {
        final provider = ExposureProvider();
        provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
        provider.setDemoMode(true);

        provider.startMonitoring();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        provider.pauseMonitoring();
        final secondsAtPause = provider.secondsElapsed;
        provider.resumeMonitoring();

        async.elapse(const Duration(seconds: 2));
        expect(provider.secondsElapsed, greaterThan(secondsAtPause));

        provider.stopMonitoring();
        async.flushMicrotasks();
        provider.dispose();
      });
    });

    test('resumeMonitoring sem monitoramento ativo não deve fazer nada', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.resumeMonitoring();
      expect(provider.isMonitoring, isFalse);
    });
  });

  group('ExposureProvider — borda: status de conexão no período de graça', () {
    test('não deve mostrar connected quando sensor está indisponível', () {
      fakeAsync((async) {
        when(() => mockClient.get(any()))
            .thenThrow(http.ClientException('Connection refused'));
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(http.ClientException('Connection refused'));

        final provider = ExposureProvider();
        provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

        provider.startMonitoring();
        async.flushMicrotasks();

        // _checkConnection falhou → deve ser disconnected
        expect(
            provider.connectionStatus, equals(ConnectionStatus.disconnected));

        // Avança além do dataFetchInterval para disparar _fetchUVData
        async.elapse(const Duration(seconds: 6));

        // Dentro do período de graça, NÃO deve ser connected
        expect(provider.connectionStatus,
            isNot(equals(ConnectionStatus.connected)));

        provider.stopMonitoring();
        async.flushMicrotasks();
        provider.dispose();
      });
    });
  });

  group('ExposureProvider — borda: setTestState', () {
    test('deve configurar isMonitoring e secondsElapsed', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setTestState(isMonitoring: true, secondsElapsed: 120);
      expect(provider.isMonitoring, isTrue);
      expect(provider.secondsElapsed, equals(120));
    });

    test('deve configurar gapDismissed', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setTestState(gapDismissed: true);
      expect(provider.gapDismissed, isTrue);
    });

    test('deve configurar disconnectedSince para cacheTimeRemaining', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      final disconnectedTime =
          DateTime.now().subtract(const Duration(seconds: 60));
      provider.setTestState(disconnectedSince: disconnectedTime);
      expect(provider.secondsDisconnected, greaterThanOrEqualTo(59));
      expect(provider.cacheTimeRemaining,
          lessThan(AppConstants.cacheExpiration.inSeconds));
    });

    test('shouldShowCacheIndicator deve ser true após threshold', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      final disconnectedTime = DateTime.now().subtract(
        AppConstants.cacheIndicatorThreshold + const Duration(seconds: 5),
      );
      provider.setTestState(disconnectedSince: disconnectedTime);
      expect(provider.shouldShowCacheIndicator, isTrue);
    });
  });
}
