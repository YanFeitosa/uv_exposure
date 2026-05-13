/// Testes de borda — StorageService
///
/// Cobre: limite de entradas no histórico.
@Tags(['edge'])
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

void main() {
  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  ExposureSession makeSession({
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
      averageUVIndex: maxUV,
    );
  }

  group('StorageService — borda: limite de entradas', () {
    test('deve respeitar limite de ${AppConstants.maxHistoryEntries} entradas',
        () async {
      final sessions = <Map<String, dynamic>>[];
      for (int i = 0; i < AppConstants.maxHistoryEntries + 5; i++) {
        final start = DateTime(2026, 1, 1).add(Duration(hours: i));
        sessions.add({
          'id': 'session-$i',
          'startTime': start.toIso8601String(),
          'endTime': start.add(const Duration(hours: 1)).toIso8601String(),
          'spf': 30.0,
          'skinType': 'Tipo II - Clara',
          'maxExposurePercent': 50.0,
          'maxUVIndex': 7.0,
          'readings': <Map<String, dynamic>>[],
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.cacheKeyExposureHistory,
        jsonEncode(sessions),
      );

      await StorageService.saveExposureSession(makeSession(
        id: 'trigger-truncation',
        startTime: DateTime(2027, 1, 1),
      ));

      final history = await StorageService.getExposureHistory();
      expect(history.length, lessThanOrEqualTo(AppConstants.maxHistoryEntries));
      expect(history.any((s) => s.id == 'trigger-truncation'), isTrue);
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('deve remover sessões mais antigas ao exceder limite', () async {
      for (int i = 0; i < 5; i++) {
        await StorageService.saveExposureSession(makeSession(
          id: 'old-$i',
          startTime: DateTime(2026, 1, 1).add(Duration(hours: i)),
        ));
      }
      final countBefore = (await StorageService.getExposureHistory()).length;

      await StorageService.saveExposureSession(makeSession(
        id: 'new-session-extra',
        startTime: DateTime(2026, 6, 1),
      ));

      final historyAfter = await StorageService.getExposureHistory();
      expect(historyAfter.length, equals(countBefore + 1));
      expect(historyAfter.any((s) => s.id == 'new-session-extra'), isTrue);
    });

    test('deve ignorar sessão em andamento ao salvar no histórico', () async {
      final openSession = ExposureSession(
        id: 'open-session',
        startTime: DateTime(2026, 1, 1, 10),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 0,
        maxUVIndex: 0,
        averageUVIndex: 0,
      );

      await StorageService.saveExposureSession(openSession);

      final history = await StorageService.getExposureHistory();
      expect(history, isEmpty);
    });

    test('deve remover entradas inválidas e incompletas do histórico',
        () async {
      final start = DateTime(2026, 5, 13, 13, 42);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.cacheKeyExposureHistory,
        jsonEncode([
          {
            'id': 'valid-session',
            'startTime': start.toIso8601String(),
            'endTime': start.add(const Duration(minutes: 5)).toIso8601String(),
            'spf': 30.0,
            'skinType': 'Tipo II - Clara',
            'maxExposurePercent': 50.0,
            'averageUVIndex': 6.5,
            'maxUVIndex': 8.0,
            'readings': <Map<String, dynamic>>[],
          },
          {
            'id': 'ghost-session',
            'startTime': start.toIso8601String(),
            'spf': 0.0,
            'skinType': 'Tipo II - Clara',
            'maxExposurePercent': 0.0,
            'averageUVIndex': 0.0,
            'maxUVIndex': 0.0,
            'readings': <Map<String, dynamic>>[],
          },
          {
            'id': '',
            'startTime': start.toIso8601String(),
            'endTime': start.add(const Duration(minutes: 1)).toIso8601String(),
            'spf': 15.0,
            'skinType': 'Tipo 0 - Demo',
            'maxExposurePercent': 10.0,
            'averageUVIndex': 5.0,
            'maxUVIndex': 7.0,
            'readings': <Map<String, dynamic>>[],
          },
        ]),
      );

      final history = await StorageService.getExposureHistory();

      expect(history.map((session) => session.id), equals(['valid-session']));

      final persisted = prefs.getString(AppConstants.cacheKeyExposureHistory);
      expect(persisted, isNotNull);
      final decoded = jsonDecode(persisted!) as List<dynamic>;
      expect(decoded.length, equals(1));
      expect((decoded.first as Map<String, dynamic>)['id'],
          equals('valid-session'));
    });
  });
}
