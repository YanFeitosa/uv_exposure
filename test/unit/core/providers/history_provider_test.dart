/// Testes unitários — HistoryProvider
///
/// Cobre: estado inicial, estatísticas, dados diários.
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

  group('HistoryProvider — estado inicial', () {
    test('deve iniciar com lista vazia', () {
      final provider = HistoryProvider();
      expect(provider.sessions, isEmpty);
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });
  });

  group('HistoryProvider — getStatistics', () {
    test('deve retornar zeros para histórico vazio', () {
      final provider = HistoryProvider();
      final stats = provider.getStatistics();
      expect(stats['totalSessions'], equals(0));
      expect(stats['totalDuration'], equals(Duration.zero));
      expect(stats['averageExposure'], equals(0.0));
      expect(stats['maxExposure'], equals(0.0));
      expect(stats['averageUVIndex'], equals(0.0));
      expect(stats['maxUVIndex'], equals(0.0));
    });

    test('deve calcular estatísticas para uma sessão', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 'single',
        startTime: DateTime(2026, 3, 15, 10),
        duration: const Duration(hours: 2),
        maxExposure: 60.0,
        maxUV: 8.0,
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();
      final stats = provider.getStatistics();

      expect(stats['totalSessions'], equals(1));
      expect(stats['totalDuration'], equals(const Duration(hours: 2)));
      expect(stats['averageExposure'], equals(60.0));
      expect(stats['maxExposure'], equals(60.0));
    });

    test('deve calcular média e máximo para múltiplas sessões', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 's1',
        startTime: DateTime(2026, 3, 15, 10),
        duration: const Duration(hours: 1),
        maxExposure: 40.0,
        maxUV: 6.0,
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 's2',
        startTime: DateTime(2026, 3, 16, 10),
        duration: const Duration(hours: 2),
        maxExposure: 80.0,
        maxUV: 10.0,
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();
      final stats = provider.getStatistics();

      expect(stats['totalSessions'], equals(2));
      expect(stats['totalDuration'], equals(const Duration(hours: 3)));
      expect(stats['averageExposure'], closeTo(60.0, 0.01));
      expect(stats['maxExposure'], equals(80.0));
      expect(stats['averageUVIndex'], closeTo(8.0, 0.01));
      expect(stats['maxUVIndex'], equals(10.0));
    });
  });

  group('HistoryProvider — getDailyExposureData', () {
    test('deve retornar lista com N dias', () async {
      final provider = HistoryProvider();
      await provider.loadHistory();
      final data = provider.getDailyExposureData(7);
      expect(data.length, equals(7));
    });

    test('deve conter chaves esperadas em cada entrada', () async {
      final provider = HistoryProvider();
      await provider.loadHistory();
      final data = provider.getDailyExposureData(7);
      for (final day in data) {
        expect(day.containsKey('date'), isTrue);
        expect(day.containsKey('exposure'), isTrue);
        expect(day.containsKey('maxUVIndex'), isTrue);
        expect(day.containsKey('duration'), isTrue);
        expect(day.containsKey('sessions'), isTrue);
      }
    });

    test('dias sem sessões devem ter valores zerados', () async {
      final provider = HistoryProvider();
      await provider.loadHistory();
      final data = provider.getDailyExposureData(7);
      for (final day in data) {
        expect(day['sessions'], equals(0));
        expect(day['exposure'], equals(0.0));
      }
    });

    test('deve agregar exposição corretamente por dia', () async {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      await StorageService.saveExposureSession(_makeSession(
        id: 'today-1',
        startTime: startOfToday.add(const Duration(hours: 8)),
        duration: const Duration(hours: 1),
        maxExposure: 30.0,
        maxUV: 5.0,
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'today-2',
        startTime: startOfToday.add(const Duration(hours: 14)),
        duration: const Duration(hours: 2),
        maxExposure: 50.0,
        maxUV: 9.0,
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();
      final data = provider.getDailyExposureData(1);

      final todayData = data.last;
      expect(todayData['sessions'], equals(2));
      expect(todayData['exposure'], equals(80.0));
      expect(todayData['maxUVIndex'], equals(9.0));
    });
  });
}
