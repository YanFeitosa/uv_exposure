/// Testes de falha e resiliência — StorageService
///
/// Cobre: recuperação de dados quando JSON está corrompido.
@Tags(['failure', 'recovery'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

void main() {
  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('StorageService — falha: JSON corrompido', () {
    test('deve retornar null para JSON corrompido de última sessão', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.cacheKeyLastSession, 'invalid-json{{{');
      final session = await StorageService.getLastSession();
      expect(session, isNull);
    });

    test('deve retornar lista vazia para JSON corrompido de histórico',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.cacheKeyExposureHistory, 'broken[json');
      final history = await StorageService.getExposureHistory();
      expect(history, isEmpty);
    });

    test('deve retornar null para JSON corrompido de cache UV', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cacheKeyLastUVData, 'bad-json');
      final cached = await StorageService.getCachedUVData();
      expect(cached, isNull);
    });
  });
}
