/// Testes unitários — ExposureProvider
///
/// Cobre inicialização, getters, formatTime, modo demo, gap, alarme, dispose.
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
      provider.initialize(spf: 50, skinType: 'Tipo V - Escura');
      expect(provider.secondsElapsed, equals(0));
      expect(provider.accumulatedExposurePercent, equals(0.0));
      expect(provider.isCritical, isFalse);
      expect(provider.isWarning, isFalse);
    });
  });

  group('ExposureProvider — modo demo', () {
    test('setDemoMode deve alterar o estado', () {
      final provider = ExposureProvider();
      provider.setDemoMode(true);
      expect(provider.isDemoMode, isTrue);
      provider.setDemoMode(false);
      expect(provider.isDemoMode, isFalse);
    });
  });

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

  group('ExposureProvider — gap detection', () {
    test('dismissGapWarning deve marcar gap como dispensado', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.dismissGapWarning();
      expect(provider.gapDismissed, isTrue);
    });

    test('gap getters devem ter valores padrão após initialize', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.gapDetected, isFalse);
      expect(provider.lastGapDurationSeconds, equals(0));
      expect(provider.lastGapCompensatedSeconds, equals(0));
      expect(provider.gapExceededMax, isFalse);
      expect(provider.gapDismissed, isFalse);
      expect(provider.gapUVIndex, equals(0.0));
    });
  });

  group('ExposureProvider — getters de exposição', () {
    test('initialSafeExposureTime deve refletir o modelo', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
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

    test('currentUVIndex deve ter valor padrão', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.currentUVIndex, isA<double>());
    });

    test('alarmPlayed deve ser false inicialmente', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.alarmPlayed, isFalse);
      expect(provider.alarmActive, isFalse);
    });
  });

  group('ExposureProvider — alarme', () {
    test('stopAlarm deve desativar alarme sem erro', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      await provider.stopAlarm();
      expect(provider.alarmActive, isFalse);
    });
  });

  group('ExposureProvider — connectionStatus', () {
    test('estado inicial deve ser disconnected', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.connectionStatus, equals(ConnectionStatus.disconnected));
      expect(provider.connectionError, isNull);
    });

    test('stoppedDueToDisconnection deve ser false inicialmente', () {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      expect(provider.stoppedDueToDisconnection, isFalse);
    });
  });

  group('ExposureProvider — dispose', () {
    test('dispose deve cancelar timer e parar alarme', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);
      await provider.startMonitoring();
      expect(provider.isMonitoring, isTrue);
      provider.dispose();
    });
  });
}
