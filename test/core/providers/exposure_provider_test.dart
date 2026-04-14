import 'dart:convert';
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

    // Mock do channel audioplayers para evitar MissingPluginException
    const MethodChannel audioChannel = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (MethodCall methodCall) async {
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

  http.Response jsonResponse(Map<String, dynamic> body) {
    return http.Response(jsonEncode(body), 200);
  }

  // ─────────────────────────────────────────────
  // Inicialização e getters
  // ─────────────────────────────────────────────
  group('ExposureProvider — inicialização', () {
    test('deve iniciar com estado padrão', () {
      final provider = ExposureProvider();
      expect(provider.isMonitoring, isFalse);
      expect(provider.connectionStatus, equals(ConnectionStatus.disconnected));
      expect(provider.alarmPlayed, isFalse);
      expect(provider.stoppedDueToDisconnection, isFalse);
      expect(provider.gapDetected, isFalse);
    });

    test('initialize deve configurar SPF e fototipo', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 50, skinType: 'Tipo III - Média Clara');

      expect(provider.spf, equals(50));
      expect(provider.skinType, equals('Tipo III - Média Clara'));
      expect(provider.accumulatedExposurePercent, equals(0.0));
    });

    test('initialize deve resetar estado anterior', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      // Simular algum estado
      provider.initialize(spf: 50, skinType: 'Tipo V - Escura');

      expect(provider.secondsElapsed, equals(0));
      expect(provider.accumulatedExposurePercent, equals(0.0));
      expect(provider.isCritical, isFalse);
      expect(provider.isWarning, isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // Modo demo
  // ─────────────────────────────────────────────
  group('ExposureProvider — modo demo', () {
    test('setDemoMode deve alterar o estado', () {
      final provider = ExposureProvider();
      provider.setDemoMode(true);
      expect(provider.isDemoMode, isTrue);

      provider.setDemoMode(false);
      expect(provider.isDemoMode, isFalse);
    });

    test('deve gerar UV simulado em modo demo ao monitorar', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();

      // Aguardar pelo menos um tick
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(provider.isMonitoring, isTrue);
      expect(provider.connectionStatus, equals(ConnectionStatus.connected));

      await provider.stopMonitoring();
    });
  });

  // ─────────────────────────────────────────────
  // Ciclo de monitoramento
  // ─────────────────────────────────────────────
  group('ExposureProvider — ciclo de monitoramento', () {
    test('startMonitoring deve ativar monitoramento', () async {
      // Mock: dispositivo acessível
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response('OK', 200));
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 5.0}));

      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true); // Usar demo para evitar dependência de rede e foreground service

      await provider.startMonitoring();
      expect(provider.isMonitoring, isTrue);

      await provider.stopMonitoring();
      expect(provider.isMonitoring, isFalse);
    });

    test('startMonitoring não deve iniciar duas vezes', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      await provider.startMonitoring(); // segunda vez

      expect(provider.isMonitoring, isTrue);
      await provider.stopMonitoring();
    });

    test('stopMonitoring em estado já parado não deve causar erro', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      // Não deve lançar exceção
      await provider.stopMonitoring();
      expect(provider.isMonitoring, isFalse);
    });

    test('deve acumular exposição durante monitoramento em demo', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();

      // Esperar alguns ticks
      await Future.delayed(const Duration(seconds: 3));

      expect(provider.secondsElapsed, greaterThan(0));
      expect(provider.accumulatedExposurePercent, greaterThan(0));

      await provider.stopMonitoring();
    });
  });

  // ─────────────────────────────────────────────
  // Pausa e retomada
  // ─────────────────────────────────────────────
  group('ExposureProvider — pausa e retomada', () {
    test('pauseMonitoring deve parar o timer mas manter isMonitoring', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      provider.pauseMonitoring();

      // isMonitoring ainda é true (pausa, não parada)
      expect(provider.isMonitoring, isTrue);

      final secondsAfterPause = provider.secondsElapsed;
      await Future.delayed(const Duration(seconds: 2));

      // Não deve ter acumulado mais
      expect(provider.secondsElapsed, equals(secondsAfterPause));

      await provider.stopMonitoring();
    });

    test('resumeMonitoring deve retomar acumulação', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      provider.pauseMonitoring();

      final secondsAtPause = provider.secondsElapsed;
      provider.resumeMonitoring();

      await Future.delayed(const Duration(seconds: 2));
      expect(provider.secondsElapsed, greaterThan(secondsAtPause));

      await provider.stopMonitoring();
    });

    test('resumeMonitoring sem monitoramento ativo não deve fazer nada', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      // Não está monitorando, não deve dar erro
      provider.resumeMonitoring();
      expect(provider.isMonitoring, isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // Formatação de tempo
  // ─────────────────────────────────────────────
  group('ExposureProvider — formatTime', () {
    late ExposureProvider provider;

    setUp(() {
      provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
    });

    test('deve formatar 0 segundos', () {
      expect(provider.formatTime(0), equals('00:00:00'));
    });

    test('deve formatar segundos', () {
      expect(provider.formatTime(45), equals('00:00:45'));
    });

    test('deve formatar minutos e segundos', () {
      expect(provider.formatTime(125), equals('00:02:05'));
    });

    test('deve formatar horas, minutos e segundos', () {
      expect(provider.formatTime(3661), equals('01:01:01'));
    });

    test('deve formatar tempo grande', () {
      expect(provider.formatTime(36000), equals('10:00:00'));
    });
  });

  // ─────────────────────────────────────────────
  // Estado de conexão e cache
  // ─────────────────────────────────────────────
  group('ExposureProvider — indicadores de conexão', () {
    test('shouldShowCacheIndicator deve ser false quando conectado', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.shouldShowCacheIndicator, isFalse);
    });

    test('secondsDisconnected deve ser 0 quando conectado', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.secondsDisconnected, equals(0));
    });

    test('cacheTimeRemaining deve retornar tempo total quando conectado', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.cacheTimeRemaining,
          equals(AppConstants.cacheExpiration.inSeconds));
    });
  });

  // ─────────────────────────────────────────────
  // Gap detection (dismissal)
  // ─────────────────────────────────────────────
  group('ExposureProvider — gap detection', () {
    test('dismissGapWarning deve marcar gap como dispensado', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      provider.dismissGapWarning();
      expect(provider.gapDismissed, isTrue);
    });
  });

  // ─────────────────────────────────────────────
  // Getters de exposição
  // ─────────────────────────────────────────────
  group('ExposureProvider — getters de exposição', () {
    test('initialSafeExposureTime deve refletir o modelo', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      // Com UV padrão (1.0): SPF 30 * TEP 15 / UV 1 * 60 = 27000
      expect(provider.initialSafeExposureTime, equals(27000));
    });

    test('remainingSafeExposureTime deve ser >= 0', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.remainingSafeExposureTime, greaterThanOrEqualTo(0));
    });

    test('isCritical e isWarning devem refletir o modelo', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.isCritical, isFalse);
      expect(provider.isWarning, isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // Persistência de sessão (salvar/restaurar)
  // ─────────────────────────────────────────────
  group('ExposureProvider — persistência de sessão', () {
    test('stopMonitoring deve salvar sessão no histórico', () async {
      final provider = ExposureProvider();
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

    test('restoreLastSession deve retornar false quando não há sessão salva', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      final restored = await provider.restoreLastSession();
      expect(restored, isFalse);
    });

    test('restoreLastSession deve restaurar sessão salva', () async {
      // Salvar uma sessão
      await StorageService.saveLastSession(
        spf: 50,
        skinType: 'Tipo V - Escura',
        accumulatedExposure: 35.0,
        secondsElapsed: 600,
      );

      final provider = ExposureProvider();
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
}
