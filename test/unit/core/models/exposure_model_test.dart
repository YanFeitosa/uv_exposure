// Testes unitários — ExposureModel, UVReading, ExposureSession
//
// Valida lógica pura de cálculo, serialização e propriedades do modelo.
import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

void main() {
  group('ExposureModel', () {
    late ExposureModel model;

    setUp(() {
      model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
    });

    group('inicialização', () {
      test('deve inicializar com TEP correto para o fototipo', () {
        expect(model.tep, equals(15.0));
      });

      test('deve inicializar com SPF correto', () {
        expect(model.spf, equals(30.0));
      });

      test('deve iniciar com 0% de exposição acumulada', () {
        expect(model.accumulatedExposurePercent, equals(0.0));
      });
    });

    group('TEP por fototipo', () {
      test('Tipo 0 - Demo: TEP = 0.1', () {
        final m = ExposureModel(spf: 30, skinType: 'Tipo 0 - Demo');
        expect(m.tep, equals(0.1));
      });

      test('Tipo I - Muito Clara: TEP = 7.5', () {
        final m = ExposureModel(spf: 30, skinType: 'Tipo I - Muito Clara');
        expect(m.tep, equals(7.5));
      });

      test('Tipo II - Clara: TEP = 15.0', () {
        expect(model.tep, equals(15.0));
      });

      test('Tipo III - Média Clara: TEP = 25.0', () {
        final m = ExposureModel(spf: 30, skinType: 'Tipo III - Média Clara');
        expect(m.tep, equals(25.0));
      });

      test('Tipo IV - Média Escura: TEP = 35.0', () {
        final m = ExposureModel(spf: 30, skinType: 'Tipo IV - Média Escura');
        expect(m.tep, equals(35.0));
      });

      test('Tipo V - Escura: TEP = 50.0', () {
        final m = ExposureModel(spf: 30, skinType: 'Tipo V - Escura');
        expect(m.tep, equals(50.0));
      });

      test('Tipo VI - Muito Escura: TEP = 75.0', () {
        final m = ExposureModel(spf: 30, skinType: 'Tipo VI - Muito Escura');
        expect(m.tep, equals(75.0));
      });

      test('todos os fototipos do AppConstants devem estar cobertos', () {
        for (final entry in AppConstants.tepBySkinType.entries) {
          final m = ExposureModel(spf: 30, skinType: entry.key);
          expect(m.tep, equals(entry.value));
        }
      });
    });

    group('calculateInitialSafeExposureTime', () {
      test('deve calcular tempo seguro corretamente para UV=5', () {
        expect(model.calculateInitialSafeExposureTime(5.0), equals(5400));
      });

      test('deve retornar valor menor para UV alto', () {
        final lowUV = model.calculateInitialSafeExposureTime(2.0);
        final highUV = model.calculateInitialSafeExposureTime(11.0);
        expect(highUV, lessThan(lowUV));
      });

      test('deve retornar valor proporcional ao SPF', () {
        final spf15 = ExposureModel(spf: 15, skinType: 'Tipo II - Clara');
        final spf50 = ExposureModel(spf: 50, skinType: 'Tipo II - Clara');
        final time15 = spf15.calculateInitialSafeExposureTime(5.0);
        final time50 = spf50.calculateInitialSafeExposureTime(5.0);
        expect(time50, greaterThan(time15));
        expect((time50 / time15), closeTo(50.0 / 15.0, 0.1));
      });
    });

    group('accumulateExposure', () {
      test('deve acumular exposição corretamente para UV=5, 60s', () {
        model.accumulateExposure(5.0, 60);
        expect(model.accumulatedExposurePercent, closeTo(1.111, 0.01));
      });

      test('deve acumular incrementalmente (múltiplas chamadas)', () {
        model.accumulateExposure(5.0, 1);
        final first = model.accumulatedExposurePercent;
        model.accumulateExposure(5.0, 1);
        expect(model.accumulatedExposurePercent, closeTo(first * 2, 0.0001));
      });

      test('acumular 1s por vez por N vezes ≈ acumular N de uma vez', () {
        final modelA = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
        final modelB = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');

        for (int i = 0; i < 300; i++) {
          modelA.accumulateExposure(5.0, 1);
        }
        modelB.accumulateExposure(5.0, 300);

        expect(modelA.accumulatedExposurePercent,
            closeTo(modelB.accumulatedExposurePercent, 0.0001));
      });

      test('deve funcionar com UV fracionário', () {
        model.accumulateExposure(3.7, 100);
        const expected = (3.7 * 100) / (15.0 * 30.0 * 60.0) * 100;
        expect(model.accumulatedExposurePercent, closeTo(expected, 0.001));
      });
    });

    group('limiares de alerta', () {
      test('isWarning deve ser true acima de 75%', () {
        model.setAccumulatedExposure(80.0);
        expect(model.isWarning, isTrue);
      });

      test('isCritical deve ser true acima de 100%', () {
        model.setAccumulatedExposure(150.0);
        expect(model.isCritical, isTrue);
      });

      test('isWarning e isCritical ambos true em 100%', () {
        model.setAccumulatedExposure(100.0);
        expect(model.isWarning, isTrue);
        expect(model.isCritical, isTrue);
      });

      test('ambos false em 0%', () {
        expect(model.isWarning, isFalse);
        expect(model.isCritical, isFalse);
      });
    });

    group('calculateRemainingSafeTime', () {
      test('deve retornar valor positivo quando há tempo restante', () {
        model.accumulateExposure(5.0, 300);
        expect(model.calculateRemainingSafeTime(300), greaterThan(0));
      });

      test('tempo restante deve diminuir com acúmulo', () {
        model.accumulateExposure(5.0, 100);
        final r1 = model.calculateRemainingSafeTime(100);
        model.accumulateExposure(5.0, 100);
        final r2 = model.calculateRemainingSafeTime(200);
        expect(r2, lessThan(r1));
      });
    });

    group('calculateSafeExposureTime', () {
      test('deve estimar tempo total seguro após algum acúmulo', () {
        model.accumulateExposure(5.0, 100);
        final totalSafe = model.calculateSafeExposureTime(100);
        expect(totalSafe, greaterThan(0));
        expect(totalSafe, closeTo(5400, 50));
      });
    });

    group('reset e setAccumulatedExposure', () {
      test('reset deve zerar exposição acumulada', () {
        model.setAccumulatedExposure(50.0);
        model.reset();
        expect(model.accumulatedExposurePercent, equals(0.0));
      });

      test('setAccumulatedExposure deve definir valor', () {
        model.setAccumulatedExposure(42.5);
        expect(model.accumulatedExposurePercent, equals(42.5));
      });
    });
  });

  group('UVReading', () {
    test('deve serializar e deserializar corretamente', () {
      final original = UVReading(
        uvIndex: 6.5,
        timestamp: DateTime(2026, 1, 15, 12, 0, 0),
      );
      final json = original.toJson();
      final restored = UVReading.fromJson(json);
      expect(restored.uvIndex, equals(original.uvIndex));
      expect(restored.timestamp, equals(original.timestamp));
    });

    test('toJson deve conter chaves esperadas', () {
      final reading = UVReading(uvIndex: 5.0, timestamp: DateTime(2026, 6, 1));
      final json = reading.toJson();
      expect(json.containsKey('uvIndex'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
    });
  });

  group('ExposureSession', () {
    test('deve calcular duração corretamente', () {
      final session = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1, 10, 0, 0),
        endTime: DateTime(2026, 1, 1, 11, 30, 0),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
      );
      expect(session.duration, equals(const Duration(hours: 1, minutes: 30)));
    });

    test('deve serializar e deserializar sessão completa', () {
      final original = ExposureSession(
        id: 'test-session-001',
        startTime: DateTime(2026, 3, 15, 10, 0, 0),
        endTime: DateTime(2026, 3, 15, 11, 0, 0),
        spf: 50,
        skinType: 'Tipo III - Média Clara',
        maxExposurePercent: 75.5,
        maxUVIndex: 8.5,
        readings: [
          UVReading(uvIndex: 7, timestamp: DateTime(2026, 3, 15, 10, 15, 0)),
          UVReading(uvIndex: 8.5, timestamp: DateTime(2026, 3, 15, 10, 30, 0)),
        ],
      );
      final json = original.toJson();
      final restored = ExposureSession.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.spf, equals(original.spf));
      expect(restored.readings.length, equals(2));
    });

    test('copyWith deve preservar campos não alterados', () {
      final original = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
      );
      final modified = original.copyWith(maxExposurePercent: 80.0);
      expect(modified.id, equals(original.id));
      expect(modified.maxExposurePercent, equals(80.0));
    });

    test('toJson deve conter todas as chaves esperadas', () {
      final session = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
      );
      final json = session.toJson();
      for (final key in [
        'id',
        'startTime',
        'endTime',
        'spf',
        'skinType',
        'maxExposurePercent',
        'maxUVIndex',
        'readings'
      ]) {
        expect(json.containsKey(key), isTrue);
      }
    });
  });
}
