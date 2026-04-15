/// Testes de borda — UVDataService
///
/// Cobre: chave ausente no JSON, valor não numérico.
@Tags(['edge', 'invalid'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';

void main() {
  group('UVData.fromJson — borda', () {
    test('deve lançar UVDataException quando nenhuma chave UV está presente',
        () {
      expect(
        () => UVData.fromJson({'temperatura': 30}),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve lançar UVDataException para valor não numérico', () {
      expect(
        () => UVData.fromJson({'uv_index': 'invalid'}),
        throwsA(isA<UVDataException>()),
      );
    });
  });
}
