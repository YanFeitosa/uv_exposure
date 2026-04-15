// Testes de integração — ExposureProvider
//
// Cobre: ciclo completo start+accumulate+stop, persistência, demo UV simulation,
// restauração de sessão.
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';

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

  group('ExposureProvider — integração: ciclo de monitoramento', () {
    test('startMonitoring deve ativar e stopMonitoring desativar', () async {
      final provider = ExposureProvider();
      addTearDown(() => provider.dispose());
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      expect(provider.isMonitoring, isTrue);

      await provider.stopMonitoring();
      expect(provider.isMonitoring, isFalse);
    });

    test('deve acumular exposição durante monitoramento em demo', () async {
      final provider = ExposureProvider();
      addTearDown(() => provider.dispose());
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      await Future.delayed(const Duration(seconds: 3));

      expect(provider.secondsElapsed, greaterThan(0));
      expect(provider.accumulatedExposurePercent, greaterThan(0));

      await provider.stopMonitoring();
    });

    test('deve gerar UV simulado em modo demo ao monitorar', () async {
      final provider = ExposureProvider();
      addTearDown(() => provider.dispose());
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(provider.isMonitoring, isTrue);
      expect(provider.connectionStatus, equals(ConnectionStatus.connected));

      await provider.stopMonitoring();
    });
  });

  group('ExposureProvider — integração: persistência de sessão', () {
    test('stopMonitoring deve salvar sessão no histórico', () async {
      final provider = ExposureProvider();
      addTearDown(() => provider.dispose());
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      await Future.delayed(const Duration(seconds: 2));
      await provider.stopMonitoring();

      final history = await StorageService.getExposureHistory();
      expect(history.length, equals(1));
      expect(history.first.spf, equals(30));
      expect(history.first.skinType, equals('Tipo II - Clara'));
    });

    test('restoreLastSession deve retornar false quando não há sessão salva',
        () async {
      final provider = ExposureProvider();
      addTearDown(() => provider.dispose());
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      final restored = await provider.restoreLastSession();
      expect(restored, isFalse);
    });

    test('restoreLastSession deve restaurar sessão salva', () async {
      await StorageService.saveLastSession(
        spf: 50,
        skinType: 'Tipo V - Escura',
        accumulatedExposure: 35.0,
        secondsElapsed: 600,
      );

      final provider = ExposureProvider();
      addTearDown(() => provider.dispose());
      provider.initialize(spf: 50, skinType: 'Tipo V - Escura');
      provider.setDemoMode(true);

      final restored = await provider.restoreLastSession();
      expect(restored, isTrue);
      expect(provider.isMonitoring, isTrue);
      expect(provider.spf, equals(50));
      expect(provider.skinType, equals('Tipo V - Escura'));
      expect(provider.accumulatedExposurePercent, closeTo(35.0, 0.1));
      expect(provider.secondsElapsed, equals(600));

      await provider.stopMonitoring();
    });
  });

  group('ExposureProvider — integração: demo UV simulation', () {
    test('deve buscar UV simulado após dataFetchInterval', () {
      fakeAsync((async) {
        final provider = ExposureProvider();
        provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
        provider.setDemoMode(true);

        provider.startMonitoring();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 7));

        expect(provider.isMonitoring, isTrue);
        expect(provider.connectionStatus, equals(ConnectionStatus.connected));
        expect(provider.currentUVIndex, isNotNull);

        provider.stopMonitoring();
        async.flushMicrotasks();
        provider.dispose();
      });
    });

    test('deve registrar leituras durante monitoramento demo', () {
      fakeAsync((async) {
        final provider = ExposureProvider();
        provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
        provider.setDemoMode(true);

        provider.startMonitoring();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 7));

        provider.stopMonitoring();
        async.flushMicrotasks();

        List<ExposureSession>? history;
        StorageService.getExposureHistory().then((h) => history = h);
        async.flushMicrotasks();

        expect(history, isNotNull);
        expect(history!.length, equals(1));
        expect(history!.first.readings.length, greaterThan(0));

        provider.dispose();
      });
    });
  });
}
