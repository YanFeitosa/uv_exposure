import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/providers/history_provider.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';

void main() {
  // Helper para criar sessões de teste
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

  // ─────────────────────────────────────────────
  // Carregamento de histórico
  // ─────────────────────────────────────────────
  group('HistoryProvider — carregamento', () {
    test('deve iniciar com lista vazia', () {
      final provider = HistoryProvider();
      expect(provider.sessions, isEmpty);
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('deve carregar histórico vazio sem erros', () async {
      final provider = HistoryProvider();
      await provider.loadHistory();

      expect(provider.sessions, isEmpty);
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('deve carregar sessões do storage', () async {
      // Popular storage com sessões
      await StorageService.saveExposureSession(_makeSession(
        id: 's1',
        startTime: DateTime(2026, 3, 10, 10),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 's2',
        startTime: DateTime(2026, 3, 15, 14),
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();

      expect(provider.sessions.length, equals(2));
      expect(provider.hasData, isTrue);
    });

    test('deve ordenar sessões por data (mais recente primeiro)', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 'old',
        startTime: DateTime(2026, 1, 1),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'new',
        startTime: DateTime(2026, 6, 1),
      ));

      final provider = HistoryProvider();
      await provider.loadHistory();

      expect(provider.sessions.first.id, equals('new'));
      expect(provider.sessions.last.id, equals('old'));
    });
  });

  // ─────────────────────────────────────────────
  // Filtros temporais
  // ─────────────────────────────────────────────
  group('HistoryProvider — filtros temporais', () {
    setUp(() async {
      await StorageService.saveExposureSession(_makeSession(
        id: 'today',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'yesterday',
        startTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ));
      await StorageService.saveExposureSession(_makeSession(
        id: 'old',
        startTime: DateTime.now().subtract(const Duration(days: 15)),
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

  // ─────────────────────────────────────────────
  // Estatísticas
  // ─────────────────────────────────────────────
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

    test('deve calcular estatísticas corretas para uma sessão', () async {
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
      expect(stats['averageUVIndex'], equals(8.0));
      expect(stats['maxUVIndex'], equals(8.0));
    });

    test('deve calcular média e máximo corretamente para múltiplas sessões', () async {
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
      expect(stats['averageExposure'], closeTo(60.0, 0.01)); // (40 + 80) / 2
      expect(stats['maxExposure'], equals(80.0));
      expect(stats['averageUVIndex'], closeTo(8.0, 0.01)); // (6 + 10) / 2
      expect(stats['maxUVIndex'], equals(10.0));
    });
  });

  // ─────────────────────────────────────────────
  // Dados diários para gráficos
  // ─────────────────────────────────────────────
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

      // Último dia é hoje
      final todayData = data.last;
      expect(todayData['sessions'], equals(2));
      expect(todayData['exposure'], equals(80.0)); // 30 + 50
      expect(todayData['maxUVIndex'], equals(9.0));
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
  });

  // ─────────────────────────────────────────────
  // Limpar histórico
  // ─────────────────────────────────────────────
  group('HistoryProvider — clearHistory', () {
    test('deve limpar todas as sessões', () async {
      await StorageService.saveExposureSession(_makeSession(
        id: 's1',
        startTime: DateTime(2026, 3, 15),
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
        id: 's1',
        startTime: DateTime(2026, 3, 15),
      ));

      final provider = HistoryProvider();
      await provider.clearHistory();

      // Verificar que o storage também está limpo
      final history = await StorageService.getExposureHistory();
      expect(history, isEmpty);
    });
  });
}
