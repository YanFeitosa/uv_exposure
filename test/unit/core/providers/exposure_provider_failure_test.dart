/// Testes de falha e resiliência — ExposureProvider
///
/// Cobre: idempotência de start/stop (double-start, stop sem monitorar).
@Tags(['failure', 'resilience'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

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
  });

  group('ExposureProvider — resiliência: double-start / double-stop', () {
    test('startMonitoring não deve iniciar duas vezes', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await provider.startMonitoring();
      await provider.startMonitoring(); // segunda chamada
      expect(provider.isMonitoring, isTrue);
      await provider.stopMonitoring();
    });

    test('stopMonitoring em estado já parado não deve causar erro', () async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      await provider.stopMonitoring();
      expect(provider.isMonitoring, isFalse);
    });
  });
}
