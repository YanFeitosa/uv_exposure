/// Testes unitários — StorageService
///
/// Cobre CRUD de sessões, preferências, cache UV, modos e permissões.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';

void main() {
  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

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

  group('StorageService — última sessão', () {
    test('deve salvar e recuperar última sessão', () async {
      await StorageService.saveLastSession(
        spf: 30.0,
        skinType: 'Tipo II - Clara',
        accumulatedExposure: 42.5,
        secondsElapsed: 1200,
      );

      final session = await StorageService.getLastSession();
      expect(session, isNotNull);
      expect(session!['spf'], equals(30.0));
      expect(session['skinType'], equals('Tipo II - Clara'));
      expect(session['accumulatedExposure'], equals(42.5));
      expect(session['secondsElapsed'], equals(1200));
      expect(session['timestamp'], isNotNull);
    });

    test('deve retornar null quando não há sessão salva', () async {
      final session = await StorageService.getLastSession();
      expect(session, isNull);
    });

    test('deve limpar última sessão', () async {
      await StorageService.saveLastSession(
        spf: 30.0,
        skinType: 'Tipo II - Clara',
        accumulatedExposure: 50.0,
        secondsElapsed: 600,
      );
      await StorageService.clearLastSession();
      final session = await StorageService.getLastSession();
      expect(session, isNull);
    });

    test('deve sobrescrever sessão anterior ao salvar nova', () async {
      await StorageService.saveLastSession(
        spf: 15.0,
        skinType: 'Tipo I - Muito Clara',
        accumulatedExposure: 20.0,
        secondsElapsed: 300,
      );
      await StorageService.saveLastSession(
        spf: 50.0,
        skinType: 'Tipo V - Escura',
        accumulatedExposure: 80.0,
        secondsElapsed: 2000,
      );

      final session = await StorageService.getLastSession();
      expect(session!['spf'], equals(50.0));
      expect(session['skinType'], equals('Tipo V - Escura'));
    });
  });

  group('StorageService — histórico de sessões', () {
    test('deve retornar lista vazia quando não há histórico', () async {
      final history = await StorageService.getExposureHistory();
      expect(history, isEmpty);
    });

    test('deve salvar e recuperar uma sessão', () async {
      final session =
          _makeSession(id: 'session-1', startTime: DateTime(2026, 3, 15, 10));
      await StorageService.saveExposureSession(session);

      final history = await StorageService.getExposureHistory();
      expect(history.length, equals(1));
      expect(history.first.id, equals('session-1'));
    });

    test('deve salvar múltiplas sessões', () async {
      for (int i = 0; i < 5; i++) {
        await StorageService.saveExposureSession(_makeSession(
          id: 'session-$i',
          startTime: DateTime(2026, 3, 15, 10 + i),
        ));
      }
      final history = await StorageService.getExposureHistory();
      expect(history.length, equals(5));
    });

    test('deve limpar todo o histórico', () async {
      await StorageService.saveExposureSession(
          _makeSession(id: 'session-1', startTime: DateTime(2026, 3, 15)));
      await StorageService.clearHistory();
      final history = await StorageService.getExposureHistory();
      expect(history, isEmpty);
    });

    test('deve preservar readings nas sessões salvas', () async {
      final session = ExposureSession(
        id: 'with-readings',
        startTime: DateTime(2026, 3, 15, 10),
        endTime: DateTime(2026, 3, 15, 11),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 60,
        maxUVIndex: 8,
        readings: [
          UVReading(uvIndex: 7, timestamp: DateTime(2026, 3, 15, 10, 15)),
          UVReading(uvIndex: 8, timestamp: DateTime(2026, 3, 15, 10, 30)),
        ],
      );
      await StorageService.saveExposureSession(session);

      final history = await StorageService.getExposureHistory();
      expect(history.first.readings.length, equals(2));
      expect(history.first.readings[0].uvIndex, equals(7));
    });
  });

  group('StorageService — filtros por data', () {
    setUp(() async {
      final now = DateTime.now();
      final sessions = [
        ExposureSession(
          id: 'today-1',
          startTime: now.subtract(const Duration(minutes: 5)),
          endTime: now.subtract(const Duration(minutes: 4)),
          spf: 30,
          skinType: 'Tipo II - Clara',
          maxExposurePercent: 40,
          maxUVIndex: 5,
        ),
        ExposureSession(
          id: 'yesterday-1',
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now
              .subtract(const Duration(days: 1))
              .add(const Duration(hours: 1)),
          spf: 30,
          skinType: 'Tipo II - Clara',
          maxExposurePercent: 60,
          maxUVIndex: 7,
        ),
        ExposureSession(
          id: 'old-1',
          startTime: now.subtract(const Duration(days: 10)),
          endTime: now
              .subtract(const Duration(days: 10))
              .add(const Duration(hours: 1)),
          spf: 30,
          skinType: 'Tipo II - Clara',
          maxExposurePercent: 80,
          maxUVIndex: 9,
        ),
      ];
      for (final s in sessions) {
        await StorageService.saveExposureSession(s);
      }
    });

    test('getTodaySessions deve retornar apenas sessões de hoje', () async {
      final today = await StorageService.getTodaySessions();
      expect(today.length, equals(1));
      expect(today.first.id, equals('today-1'));
    });

    test('getSessionsLastDays(3) deve retornar sessões de hoje e ontem',
        () async {
      final recent = await StorageService.getSessionsLastDays(3);
      expect(recent.length, equals(2));
    });

    test('getSessionsLastDays(30) deve retornar todas as sessões', () async {
      final all = await StorageService.getSessionsLastDays(30);
      expect(all.length, equals(3));
    });

    test('getSessionsInRange deve filtrar corretamente', () async {
      final now = DateTime.now();
      final sessions = await StorageService.getSessionsInRange(
        now.subtract(const Duration(days: 2)),
        now,
      );
      expect(sessions.length, equals(2));
    });
  });

  group('StorageService — cache UV', () {
    test('deve salvar e recuperar cache UV', () async {
      await StorageService.cacheUVData(7.5);
      final cached = await StorageService.getCachedUVData();
      expect(cached, isNotNull);
      expect(cached!['uvIndex'], equals(7.5));
    });

    test('deve retornar null quando cache está vazio', () async {
      final cached = await StorageService.getCachedUVData();
      expect(cached, isNull);
    });
  });

  group('StorageService — preferências do usuário', () {
    test('deve salvar e recuperar SPF padrão', () async {
      await StorageService.saveUserPreferences(defaultSpf: '50');
      final prefs = await StorageService.getUserPreferences();
      expect(prefs['defaultSpf'], equals('50'));
    });

    test('deve salvar e recuperar fototipo padrão', () async {
      await StorageService.saveUserPreferences(
          defaultSkinType: 'Tipo III - Média Clara');
      final prefs = await StorageService.getUserPreferences();
      expect(prefs['defaultSkinType'], equals('Tipo III - Média Clara'));
    });

    test('deve retornar null para preferência não definida', () async {
      final prefs = await StorageService.getUserPreferences();
      expect(prefs['defaultSpf'], isNull);
      expect(prefs['defaultSkinType'], isNull);
    });

    test('deve salvar e recuperar fototipo via saveSkinType', () async {
      await StorageService.saveSkinType('Tipo V - Escura');
      final skinType = await StorageService.getSkinType();
      expect(skinType, equals('Tipo V - Escura'));
    });

    test('getSkinType deve retornar null quando não definido', () async {
      final skinType = await StorageService.getSkinType();
      expect(skinType, isNull);
    });
  });

  group('StorageService — configurações do app', () {
    test('modo demo: padrão deve ser false', () async {
      final demo = await StorageService.getDemoMode();
      expect(demo, isFalse);
    });

    test('deve salvar e recuperar modo demo', () async {
      await StorageService.setDemoMode(true);
      expect(await StorageService.getDemoMode(), isTrue);
      await StorageService.setDemoMode(false);
      expect(await StorageService.getDemoMode(), isFalse);
    });

    test('alarme sonoro: padrão deve ser true', () async {
      final enabled = await StorageService.isSoundAlarmEnabled();
      expect(enabled, isTrue);
    });

    test('deve salvar e recuperar estado do alarme sonoro', () async {
      await StorageService.setSoundAlarmEnabled(false);
      expect(await StorageService.isSoundAlarmEnabled(), isFalse);
      await StorageService.setSoundAlarmEnabled(true);
      expect(await StorageService.isSoundAlarmEnabled(), isTrue);
    });
  });

  group('StorageService — permissão de notificação', () {
    test('padrão deve ser false (ainda não perguntou)', () async {
      final asked = await StorageService.wasNotificationPermissionAsked();
      expect(asked, isFalse);
    });

    test('deve marcar como perguntado', () async {
      await StorageService.setNotificationPermissionAsked();
      final asked = await StorageService.wasNotificationPermissionAsked();
      expect(asked, isTrue);
    });

    test('deve resetar estado de permissão', () async {
      await StorageService.setNotificationPermissionAsked();
      await StorageService.resetNotificationPermissionAsked();
      final asked = await StorageService.wasNotificationPermissionAsked();
      expect(asked, isFalse);
    });
  });
}
