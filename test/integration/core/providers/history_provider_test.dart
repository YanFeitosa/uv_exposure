/// Testes de integração — HistoryProvider
///
/// Cobre: load/filter/clear persistidos, ordenação, filtros temporais.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/providers/history_provider.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';

void main() {
  ExposureSession _makeSession({
    required String id,
    required DateTime startTime,
    Duration duration = const Duration(hours: 1),
    double spf = 30,
    String skinType = 'Tipo II - Clara',
    double maxExposure = 50,
    double maxUV = 7,
  }) {
    return ExposureSession(
      id: id,
      startTime: startTime,
      endTime: startTime.add(duration),
      spf: spf,
      skinType: skinType,
      maxExposurePercent: maxExposure,
      maxUVIndex: maxUV,
    );
  }

  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('HistoryProvider — integração: carregamento', () {
    test('deve carregar histórico vazio sem erros', () async {
      final provider = HistoryProvider();
      await provider.loadHistory();
      expect(provider.sessions, isEmpty);
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('deve carregar sessões do storage', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 's1', startTime: DateTime(2026, 3, 10, 10),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 's2', startTime: DateTime(2026, 3, 15, 14),
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();
      expect(provider.sessions.length, equals(2));
      expect(provider.hasData, isTrue);
    });

    test('deve ordenar sessões por data (mais recente primeiro)', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 'old', startTime: DateTime(2026, 1, 1),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'new', startTime: DateTime(2026, 6, 1),
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();
      expect(provider.sessions.first.id, equals('new'));
      expect(provider.sessions.last.id, equals('old'));
    });
  });

  group('HistoryProvider — integração: filtros temporais', () {
    setUp(() async {
      final now = DateTime.now();
      await StorageService.saveExposureSession(_makeSession(
        id: 'today',
        startTime: now.subtract(const Duration(minutes: 5)),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'yesterday',
        startTime: now.subtract(const Duration(days: 1)),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'old',
        startTime: now.subtract(const Duration(days: 15)),
      ));
    });

    test('loadTodaySessions deve filtrar sessões de hoje', () async {
      final provider = HistoryProvider();
      await provider.loadTodaySessions();
      expect(provider.sessions.length, equals(1));
      expect(provider.sessions.first.id, equals('today'));
    });

    test('loadSessionsLastDays(3) deve filtrar corretamente', () async {
      final provider = HistoryProvider();
      await provider.loadSessionsLastDays(3);
      expect(provider.sessions.length, equals(2));
    });

    test('loadSessionsLastDays(30) deve incluir todas', () async {
      final provider = HistoryProvider();
      await provider.loadSessionsLastDays(30);
      expect(provider.sessions.length, equals(3));
    });
  });

  group('HistoryProvider — integração: clearHistory', () {
    test('deve limpar todas as sessões', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 's1', startTime: DateTime(2026, 3, 15),
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();
      expect(provider.hasData, isTrue);

      await provider.clearHistory();
      expect(provider.sessions, isEmpty);
      expect(provider.hasData, isFalse);
    });

    test('deve persistir a limpeza no storage', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 's1', startTime: DateTime(2026, 3, 15),
      ));

      final provider = HistoryProvider();
      await provider.clearHistory();

      final history = await StorageService.getExposureHistory();
      expect(history, isEmpty);
    });
  });
}
