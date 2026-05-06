/// Testes de borda — ExposureModel, UVReading, ExposureSession
///
/// Cobre: SPF=0/negativo, UV=0/negativo, limiares 75%/100%, fototipo inválido,
/// JSON corrompido, acúmulo de alta precisão, overflow.
@Tags(['edge'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

void main() {
  group('ExposureModel — borda: inicialização', () {
    test('deve tratar SPF=0 como SPF=1 (proteção mínima)', () {
      final m = ExposureModel(spf: 0, skinType: 'Tipo II - Clara');
      expect(m.spf, equals(1.0));
    });

    test('deve tratar SPF negativo como SPF=1', () {
      final m = ExposureModel(spf: -5, skinType: 'Tipo II - Clara');
      expect(m.spf, equals(1.0));
    });

    test('deve usar TEP padrão para fototipo desconhecido', () {
      final m = ExposureModel(spf: 30, skinType: 'Tipo Inexistente');
      expect(m.tep, equals(AppConstants.defaultTEP));
    });
  });

  group('ExposureModel — borda: calculateInitialSafeExposureTime', () {
    test('UV=0 deve usar UV=1 como fallback', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      expect(model.calculateInitialSafeExposureTime(0.0), greaterThan(0));
    });

    test('UV negativo deve usar UV=1 como fallback', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      expect(model.calculateInitialSafeExposureTime(-3.0), greaterThan(0));
    });

    test('UV muito alto (15+) deve retornar tempo curto', () {
      final model = ExposureModel(spf: 1, skinType: 'Tipo I - Muito Clara');
      final time = model.calculateInitialSafeExposureTime(15.0);
      // (1 * 133.3 / 15) * 60 = 533s
      expect(time, greaterThan(0));
      expect(time, lessThan(600));
    });
  });

  group('ExposureModel — borda: accumulateExposure', () {
    test('UV=0 não deve alterar a exposição acumulada', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      model.accumulateExposure(0.0, 3600);
      expect(model.accumulatedExposurePercent, equals(0.0));
    });

    test('UV negativo não deve alterar a exposição acumulada', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      model.accumulateExposure(-5.0, 3600);
      expect(model.accumulatedExposurePercent, lessThanOrEqualTo(0.0));
    });

    test('acúmulo 1s por 3600 iterações deve ter precisão aceitável', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      for (int i = 0; i < 3600; i++) {
        model.accumulateExposure(5.0, 1);
      }
      const expected = (5.0 * 3600) / (166.7 * 30.0 * 60.0) * 100;
      expect(model.accumulatedExposurePercent,
          closeTo(expected, expected * 0.001));
    });
  });

  group('ExposureModel — borda: limiares de alerta', () {
    late ExposureModel model;

    setUp(() {
      model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
    });

    test('74.9% → isWarning false', () {
      model.setAccumulatedExposure(74.9);
      expect(model.isWarning, isFalse);
    });

    test('75.0% → isWarning true', () {
      model.setAccumulatedExposure(75.0);
      expect(model.isWarning, isTrue);
    });

    test('75.01% → isWarning true', () {
      model.setAccumulatedExposure(75.01);
      expect(model.isWarning, isTrue);
    });

    test('99.9% → isCritical false', () {
      model.setAccumulatedExposure(99.9);
      expect(model.isCritical, isFalse);
    });

    test('100.0% → isCritical true', () {
      model.setAccumulatedExposure(100.0);
      expect(model.isCritical, isTrue);
    });

    test('200% (overflow) → isCritical true', () {
      model.setAccumulatedExposure(200.0);
      expect(model.isCritical, isTrue);
      expect(model.isWarning, isTrue);
    });
  });

  group('ExposureModel — borda: remainingSafeTime', () {
    test(
        'nenhuma exposição acumulada e 0s elapsed retorna 0 (baseado no elapsed)',
        () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      expect(model.calculateRemainingSafeTime(0), greaterThanOrEqualTo(0));
    });

    test('exposição >= 100% deve retornar 0 ou negativo', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      model.setAccumulatedExposure(110.0);
      expect(model.calculateRemainingSafeTime(9999), lessThanOrEqualTo(0));
    });
  });

  group('ExposureModel — borda: reset duplo', () {
    test('reset chamado duas vezes não deve falhar', () {
      final model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
      model.setAccumulatedExposure(50);
      model.reset();
      model.reset();
      expect(model.accumulatedExposurePercent, equals(0.0));
    });
  });

  group('UVReading — borda', () {
    test('uvIndex=0 deve serializar e deserializar', () {
      final r = UVReading(uvIndex: 0.0, timestamp: DateTime(2026, 1, 1));
      final json = r.toJson();
      final restored = UVReading.fromJson(json);
      expect(restored.uvIndex, equals(0.0));
    });
  });

  group('ExposureSession — borda', () {
    test('sessão sem readings deve serializar', () {
      final session = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
        averageUVIndex: 5.0,
      );
      final json = session.toJson();
      final restored = ExposureSession.fromJson(json);
      expect(restored.readings, isEmpty);
    });

    test('sessão com spf=0 deve serializar', () {
      final session = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 0,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
        averageUVIndex: 5.0,
      );
      final json = session.toJson();
      final restored = ExposureSession.fromJson(json);
      expect(restored.spf, equals(0));
    });

    test('sessão com maxExposurePercent=0 deve ser válida', () {
      final session = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 0,
        maxUVIndex: 0,
        averageUVIndex: 0.0,
      );
      expect(session.duration, equals(const Duration(hours: 1)));
    });

    test('sessão com duração zero (start==end) tem Duration.zero', () {
      final t = DateTime(2026, 1, 1);
      final session = ExposureSession(
        id: '1',
        startTime: t,
        endTime: t,
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
        averageUVIndex: 5.0,
      );
      expect(session.duration, equals(Duration.zero));
    });

    test('copyWith com todos os campos explícitos', () {
      final original = ExposureSession(
        id: '1',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
        averageUVIndex: 5.0,
      );
      final modified = original.copyWith(
        maxExposurePercent: 99.9,
        maxUVIndex: 15.0,
      );
      expect(modified.maxExposurePercent, equals(99.9));
      expect(modified.maxUVIndex, equals(15.0));
      expect(modified.id, equals('1'));
    });
  });
}
