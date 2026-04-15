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

  group('StorageService — borda: limite de entradas', () {
    test('deve respeitar limite de ${AppConstants.maxHistoryEntries} entradas',
        () async {
      final sessions = <Map<String, dynamic>>[];
      for (int i = 0; i < AppConstants.maxHistoryEntries + 5; i++) {
        final start = DateTime(2026, 1, 1).add(Duration(hours: i));
        sessions.add({
          'id': 'session-$i',
          'startTime': start.toIso8601String(),
          'endTime':
              start.add(const Duration(hours: 1)).toIso8601String(),
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

      await StorageService.saveExposureSession(_makeSession(
        id: 'trigger-truncation',
        startTime: DateTime(2027, 1, 1),
      ));

      final history = await StorageService.getExposureHistory();
      expect(
          history.length, lessThanOrEqualTo(AppConstants.maxHistoryEntries));
      expect(history.any((s) => s.id == 'trigger-truncation'), isTrue);
    }, timeout: Timeout(Duration(minutes: 1)));

    test('deve remover sessões mais antigas ao exceder limite', () async {
      for (int i = 0; i < 5; i++) {
        await StorageService.saveExposureSession(_makeSession(
          id: 'old-$i',
          startTime: DateTime(2026, 1, 1).add(Duration(hours: i)),
        ));
      }
      final countBefore = (await StorageService.getExposureHistory()).length;

      await StorageService.saveExposureSession(_makeSession(
        id: 'new-session-extra',
        startTime: DateTime(2026, 6, 1),
      ));

      final historyAfter = await StorageService.getExposureHistory();
      expect(historyAfter.length, equals(countBefore + 1));
      expect(historyAfter.any((s) => s.id == 'new-session-extra'), isTrue);
    });
  });
}
