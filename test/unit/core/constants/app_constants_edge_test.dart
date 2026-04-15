/// Testes de borda — AppConstants
///
/// Cobre: integridade dos mappings TEP, valores limites das constantes,
/// consistência entre constantes relacionadas.
@Tags(['edge'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

void main() {
  group('AppConstants — borda: TEP mapping', () {
    test('todos os TEP devem ser positivos', () {
      for (final entry in AppConstants.tepBySkinType.entries) {
        expect(entry.value, greaterThan(0),
            reason: '${entry.key} tem TEP ${entry.value} <= 0');
      }
    });

    test('defaultTEP deve ser positivo', () {
      expect(AppConstants.defaultTEP, greaterThan(0));
    });

    test('TEP deve aumentar conforme fototipo escurece', () {
      final values = AppConstants.tepBySkinType.values.toList();
      // Excluir o demo (primeiro) — verificar I a VI em ordem crescente
      for (int i = 2; i < values.length; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]),
            reason: 'TEP[$i] < TEP[${i - 1}]');
      }
    });
  });

  group('AppConstants — borda: limites de tempo', () {
    test('cacheExpiration deve ser positivo', () {
      expect(AppConstants.cacheExpiration.inSeconds, greaterThan(0));
    });

    test('cacheIndicatorThreshold deve ser menor que cacheExpiration', () {
      expect(AppConstants.cacheIndicatorThreshold,
          lessThan(AppConstants.cacheExpiration));
    });

    test('maxHistoryEntries deve ser >= 1', () {
      expect(AppConstants.maxHistoryEntries, greaterThanOrEqualTo(1));
    });
  });

  group('AppConstants — borda: SPF lista', () {
    test('availableSpfValues deve conter apenas valores não-negativos', () {
      for (final spf in AppConstants.availableSpfValues) {
        expect(spf, greaterThanOrEqualTo(0), reason: 'SPF $spf é negativo');
      }
    });

    test('availableSpfValues deve estar em ordem crescente', () {
      for (int i = 1; i < AppConstants.availableSpfValues.length; i++) {
        expect(AppConstants.availableSpfValues[i],
            greaterThan(AppConstants.availableSpfValues[i - 1]),
            reason: 'SPF não está em ordem');
      }
    });
  });
}
