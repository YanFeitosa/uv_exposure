import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';

void main() {
  // ─────────────────────────────────────────────
  // AppConstants — Validação de coerência das constantes
  // ─────────────────────────────────────────────
  group('AppConstants — TEP por fototipo', () {
    test('todos os fototipos de AppStrings devem ter TEP correspondente', () {
      for (final skinType in AppStrings.skinTypes) {
        expect(
          AppConstants.tepBySkinType.containsKey(skinType),
          isTrue,
          reason: 'Fototipo "$skinType" não tem TEP definido em AppConstants',
        );
      }
    });

    test('valores de TEP devem ser positivos e crescentes por fototipo', () {
      final teps = AppConstants.tepBySkinType.values.toList();
      for (final tep in teps) {
        expect(tep, greaterThan(0), reason: 'TEP deve ser positivo: $tep');
      }
    });

    test('TEP Tipo I deve ser menor que TEP Tipo VI', () {
      final tepI = AppConstants.tepBySkinType['Tipo I - Muito Clara']!;
      final tepVI = AppConstants.tepBySkinType['Tipo VI - Muito Escura']!;
      expect(tepI, lessThan(tepVI));
    });

    test('defaultTEP deve ser valor válido e razoável', () {
      expect(AppConstants.defaultTEP, greaterThan(0));
      expect(AppConstants.defaultTEP, equals(15.0)); // Tipo II
    });
  });

  group('AppConstants — limiares de exposição', () {
    test('limiar de aviso deve ser menor que limiar crítico', () {
      expect(AppConstants.exposureWarningThreshold,
          lessThan(AppConstants.exposureCriticalThreshold));
    });

    test('limiar de aviso deve ser 75%', () {
      expect(AppConstants.exposureWarningThreshold, equals(75.0));
    });

    test('limiar crítico deve ser 100%', () {
      expect(AppConstants.exposureCriticalThreshold, equals(100.0));
    });
  });

  group('AppConstants — configuração de rede', () {
    test('httpTimeout deve ser adequado (5-30s)', () {
      expect(AppConstants.httpTimeout.inSeconds, greaterThanOrEqualTo(5));
      expect(AppConstants.httpTimeout.inSeconds, lessThanOrEqualTo(30));
    });

    test('connectionCheckTimeout deve ser menor que httpTimeout', () {
      expect(AppConstants.connectionCheckTimeout,
          lessThan(AppConstants.httpTimeout));
    });

    test('cacheExpiration deve ser positiva', () {
      expect(AppConstants.cacheExpiration.inSeconds, greaterThan(0));
    });

    test('URLs do dispositivo devem estar formatadas', () {
      expect(AppConstants.deviceBaseUrl, startsWith('http'));
      expect(AppConstants.deviceDataEndpoint, startsWith('/'));
    });
  });

  group('AppConstants — compensação de gap', () {
    test('maxGapSimulationSeconds deve ser razoável (> 0, <= 3600)', () {
      expect(AppConstants.maxGapSimulationSeconds, greaterThan(0));
      expect(AppConstants.maxGapSimulationSeconds, lessThanOrEqualTo(3600));
    });

    test('gapDetectionThresholdSeconds deve ser > 1', () {
      expect(AppConstants.gapDetectionThresholdSeconds, greaterThan(1));
    });
  });

  group('AppConstants — histórico', () {
    test('maxHistoryEntries deve ser positivo', () {
      expect(AppConstants.maxHistoryEntries, greaterThan(0));
    });

    test('saveProgressInterval deve ser positivo', () {
      expect(AppConstants.saveProgressInterval, greaterThan(0));
    });
  });

  group('AppConstants — IDs de notificação devem ser únicos', () {
    test('todos os IDs de notificação devem ser distintos', () {
      final ids = {
        AppConstants.notificationWarningId,
        AppConstants.notificationCriticalId,
        AppConstants.notificationCacheId,
        AppConstants.notificationStoppedId,
        AppConstants.notificationGapId,
      };
      expect(ids.length, equals(5),
          reason: 'IDs de notificação duplicados detectados');
    });
  });

  // ─────────────────────────────────────────────
  // AppStrings — Validação de completude
  // ─────────────────────────────────────────────
  group('AppStrings', () {
    test('deve ter nome e título do app', () {
      expect(AppStrings.appName, isNotEmpty);
      expect(AppStrings.appTitle, isNotEmpty);
    });

    test('deve ter fototipos incluindo Demo', () {
      expect(AppStrings.skinTypes, contains('Tipo 0 - Demo'));
      expect(AppStrings.skinTypes.length, greaterThanOrEqualTo(7));
    });

    test('deve ter valores de SPF incluindo 0 (sem protetor)', () {
      expect(AppStrings.spfValues, contains('0'));
      expect(AppStrings.spfValues.length, greaterThanOrEqualTo(4));
    });

    test('strings de notificação devem ter conteúdo', () {
      expect(AppStrings.notificationChannelId, isNotEmpty);
      expect(AppStrings.exposureWarningTitle, isNotEmpty);
      expect(AppStrings.exposureCriticalTitle, isNotEmpty);
      expect(AppStrings.exposureWarningBody, contains('{percent}'));
    });

    test('strings de gap devem ter placeholders', () {
      expect(AppStrings.gapDialogBody, contains('{duration}'));
      expect(AppStrings.gapDialogBody, contains('{uvIndex}'));
      expect(AppStrings.gapDialogBodyExceeded, contains('{maxMinutes}'));
    });

    test('strings de parada devem ter placeholder de minutos', () {
      expect(AppStrings.stoppedNotificationBody, contains('{minutes}'));
      expect(AppStrings.monitoringStoppedNoConnection, contains('{minutes}'));
    });
  });
}
