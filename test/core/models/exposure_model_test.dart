import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

void main() {
  // ─────────────────────────────────────────────
  // ExposureModel — Testes abrangentes
  // ─────────────────────────────────────────────
  group('ExposureModel', () {
    late ExposureModel model;

    setUp(() {
      model = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
    });

    // ── Inicialização ──
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

    // ── TEP por fototipo ──
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
        final m = ExposureModel(spf: 30, skinType: 'Tipo II - Clara');
        expect(m.tep, equals(15.0));
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
          expect(m.tep, equals(entry.value),
              reason: 'TEP incorreto para ${entry.key}');
        }
      });
    });

    // ── Tempo seguro inicial ──
    group('calculateInitialSafeExposureTime', () {
      test('deve calcular tempo seguro corretamente para UV=5', () {
        // SPF 30 * TEP 15 / UV 5 = 90 minutos = 5400 segundos
        final safeTime = model.calculateInitialSafeExposureTime(5.0);
        expect(safeTime, equals(5400));
      });

      test('deve tratar UV=0 como UV=1', () {
        final safeTime = model.calculateInitialSafeExposureTime(0.0);
        // SPF 30 * TEP 15 / UV 1 = 450 minutos = 27000 segundos
        expect(safeTime, equals(27000));
      });

      test('deve tratar UV negativo como UV=1', () {
        final safeTime = model.calculateInitialSafeExposureTime(-3.0);
        expect(safeTime, equals(27000));
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
        // SPF 50 deve dar ~3.33x mais tempo que SPF 15
        expect(time50, greaterThan(time15));
        expect((time50 / time15), closeTo(50.0 / 15.0, 0.1));
      });

      test('deve funcionar com UV extremo (20+)', () {
        final safeTime = model.calculateInitialSafeExposureTime(20.0);
        // SPF 30 * TEP 15 / UV 20 * 60 = 1350 segundos
        expect(safeTime, equals(1350));
      });

      test('deve funcionar com SPF=0 (tratado como 1)', () {
        final m = ExposureModel(spf: 0, skinType: 'Tipo II - Clara');
        final safeTime = m.calculateInitialSafeExposureTime(5.0);
        // SPF 1 * TEP 15 / UV 5 * 60 = 180 segundos
        expect(safeTime, equals(180));
      });
    });

    // ── Acumulação de exposição ──
    group('accumulateExposure', () {
      test('deve acumular exposição corretamente para UV=5, 60s', () {
        // Exposure = (5 * 60) / (15 * 30 * 60) * 100 ≈ 1.111%
        model.accumulateExposure(5.0, 60);
        expect(model.accumulatedExposurePercent, closeTo(1.111, 0.01));
      });

      test('não deve acumular para UV=0', () {
        model.accumulateExposure(0.0, 60);
        expect(model.accumulatedExposurePercent, equals(0.0));
      });

      test('não deve acumular para UV negativo', () {
        model.accumulateExposure(-3.0, 60);
        expect(model.accumulatedExposurePercent, equals(0.0));
      });

      test('deve acumular incrementalmente (múltiplas chamadas)', () {
        model.accumulateExposure(5.0, 1);
        final first = model.accumulatedExposurePercent;
        model.accumulateExposure(5.0, 1);
        final second = model.accumulatedExposurePercent;
        expect(second, closeTo(first * 2, 0.0001));
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

      test('deve atingir ~100% no tempo seguro previsto', () {
        // Tempo seguro para UV=5: 5400 segundos
        // Acumular exposição por 5400 segundos a UV=5
        model.accumulateExposure(5.0, 5400);
        expect(model.accumulatedExposurePercent, closeTo(100.0, 0.1));
      });

      test('deve ultrapassar 100% se continuar acumulando', () {
        model.accumulateExposure(5.0, 7000);
        expect(model.accumulatedExposurePercent, greaterThan(100.0));
      });

      test('acumulação longa (3600 iterações de 1s) sem perda de precisão', () {
        for (int i = 0; i < 3600; i++) {
          model.accumulateExposure(5.0, 1);
        }
        // Esperado: (5 * 3600) / (15 * 30 * 60) * 100 = 66.67%
        expect(model.accumulatedExposurePercent, closeTo(66.667, 0.01));
      });

      test('deve funcionar com UV fracionário', () {
        model.accumulateExposure(3.7, 100);
        final expected = (3.7 * 100) / (15.0 * 30.0 * 60.0) * 100;
        expect(model.accumulatedExposurePercent, closeTo(expected, 0.001));
      });

      test('deve funcionar com timeSeconds=0 (sem mudança)', () {
        model.accumulateExposure(5.0, 0);
        expect(model.accumulatedExposurePercent, equals(0.0));
      });
    });

    // ── Limiares de aviso e crítico ──
    group('limiares de alerta', () {
      test('isWarning deve ser false abaixo de 75%', () {
        model.setAccumulatedExposure(74.99);
        expect(model.isWarning, isFalse);
      });

      test('isWarning deve ser true em exatamente 75%', () {
        model.setAccumulatedExposure(75.0);
        expect(model.isWarning, isTrue);
      });

      test('isWarning deve ser true acima de 75%', () {
        model.setAccumulatedExposure(80.0);
        expect(model.isWarning, isTrue);
      });

      test('isCritical deve ser false abaixo de 100%', () {
        model.setAccumulatedExposure(99.99);
        expect(model.isCritical, isFalse);
      });

      test('isCritical deve ser true em exatamente 100%', () {
        model.setAccumulatedExposure(100.0);
        expect(model.isCritical, isTrue);
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

    // ── Tempo restante ──
    group('calculateRemainingSafeTime', () {
      test('deve retornar valor positivo quando há tempo restante', () {
        model.accumulateExposure(5.0, 300);
        final remaining = model.calculateRemainingSafeTime(300);
        expect(remaining, greaterThan(0));
      });

      test('deve retornar 0 quando exposição atinge 100%', () {
        model.accumulateExposure(5.0, 5400); // ~100%
        final remaining = model.calculateRemainingSafeTime(5400);
        expect(remaining, equals(0));
      });

      test('deve retornar 0 quando exposição ultrapassa 100%', () {
        model.setAccumulatedExposure(150.0);
        final remaining = model.calculateRemainingSafeTime(6000);
        expect(remaining, equals(0));
      });

      test('tempo restante deve diminuir com acúmulo', () {
        model.accumulateExposure(5.0, 100);
        final r1 = model.calculateRemainingSafeTime(100);
        model.accumulateExposure(5.0, 100);
        final r2 = model.calculateRemainingSafeTime(200);
        expect(r2, lessThan(r1));
      });
    });

    // ── calculateSafeExposureTime ──
    group('calculateSafeExposureTime', () {
      test('deve retornar 0 quando exposição é muito pequena', () {
        expect(model.calculateSafeExposureTime(100), equals(0));
      });

      test('deve estimar tempo total seguro após algum acúmulo', () {
        model.accumulateExposure(5.0, 100);
        final totalSafe = model.calculateSafeExposureTime(100);
        // totalSafe ≈ 5400 (tempo seguro para UV=5)
        expect(totalSafe, greaterThan(0));
        expect(totalSafe, closeTo(5400, 50));
      });
    });

    // ── Reset e estado ──
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

      test('setAccumulatedExposure deve clampar valores negativos a 0', () {
        model.setAccumulatedExposure(-10.0);
        expect(model.accumulatedExposurePercent, equals(0.0));
      });

      test('setAccumulatedExposure deve aceitar valores acima de 100', () {
        model.setAccumulatedExposure(200.0);
        expect(model.accumulatedExposurePercent, equals(200.0));
      });
    });
  });

  // ─────────────────────────────────────────────
  // UVReading — Serialização
  // ─────────────────────────────────────────────
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

    test('deve aceitar UV=0 na serialização', () {
      final reading = UVReading(
        uvIndex: 0.0,
        timestamp: DateTime.now(),
      );
      final json = reading.toJson();
      final restored = UVReading.fromJson(json);
      expect(restored.uvIndex, equals(0.0));
    });

    test('deve aceitar UV alto na serialização', () {
      final reading = UVReading(
        uvIndex: 15.3,
        timestamp: DateTime.now(),
      );
      final json = reading.toJson();
      final restored = UVReading.fromJson(json);
      expect(restored.uvIndex, equals(15.3));
    });

    test('toJson deve conter chaves esperadas', () {
      final reading = UVReading(
        uvIndex: 5.0,
        timestamp: DateTime(2026, 6, 1),
      );
      final json = reading.toJson();
      expect(json.containsKey('uvIndex'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
    });
  });

  // ─────────────────────────────────────────────
  // ExposureSession — Serialização e propriedades
  // ─────────────────────────────────────────────
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

    test('duração sem endTime deve usar DateTime.now()', () {
      final session = ExposureSession(
        id: '1',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 10,
        maxUVIndex: 3,
      );
      // Deve ser ~5 minutos (aceitar margem de 2 segundos)
      expect(session.duration.inSeconds, closeTo(300, 2));
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
          UVReading(uvIndex: 6, timestamp: DateTime(2026, 3, 15, 10, 45, 0)),
        ],
      );

      final json = original.toJson();
      final restored = ExposureSession.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.startTime, equals(original.startTime));
      expect(restored.endTime, equals(original.endTime));
      expect(restored.spf, equals(original.spf));
      expect(restored.skinType, equals(original.skinType));
      expect(restored.maxExposurePercent, equals(original.maxExposurePercent));
      expect(restored.maxUVIndex, equals(original.maxUVIndex));
      expect(restored.readings.length, equals(3));
      expect(restored.readings[1].uvIndex, equals(8.5));
    });

    test('deve deserializar sessão sem endTime (null)', () {
      final json = {
        'id': 'session-no-end',
        'startTime': '2026-03-15T10:00:00.000',
        'endTime': null,
        'spf': 30,
        'skinType': 'Tipo II - Clara',
        'maxExposurePercent': 25.0,
        'maxUVIndex': 5.0,
        'readings': [],
      };
      final session = ExposureSession.fromJson(json);
      expect(session.endTime, isNull);
    });

    test('deve deserializar sessão sem lista de readings', () {
      final json = {
        'id': 'session-no-readings',
        'startTime': '2026-03-15T10:00:00.000',
        'endTime': '2026-03-15T11:00:00.000',
        'spf': 30,
        'skinType': 'Tipo II - Clara',
        'maxExposurePercent': 50.0,
        'maxUVIndex': 7.0,
      };
      final session = ExposureSession.fromJson(json);
      expect(session.readings, isEmpty);
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
      expect(modified.spf, equals(original.spf));
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
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('startTime'), isTrue);
      expect(json.containsKey('endTime'), isTrue);
      expect(json.containsKey('spf'), isTrue);
      expect(json.containsKey('skinType'), isTrue);
      expect(json.containsKey('maxExposurePercent'), isTrue);
      expect(json.containsKey('maxUVIndex'), isTrue);
      expect(json.containsKey('readings'), isTrue);
    });

    test('serialização round-trip com SPF=0', () {
      final original = ExposureSession(
        id: 'spf-zero',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        spf: 0,
        skinType: 'Tipo I - Muito Clara',
        maxExposurePercent: 90,
        maxUVIndex: 11,
      );
      final json = original.toJson();
      final restored = ExposureSession.fromJson(json);
      expect(restored.spf, equals(0));
    });

    test('fromJson defensivo: campos faltando usa fallbacks', () {
      final json = <String, dynamic>{
        'startTime': '2026-01-01T10:00:00.000',
      };
      final session = ExposureSession.fromJson(json);
      expect(session.id, equals('unknown'));
      expect(session.spf, equals(0.0));
      expect(session.skinType, equals('Tipo II - Clara'));
      expect(session.maxExposurePercent, equals(0.0));
      expect(session.maxUVIndex, equals(0.0));
      expect(session.readings, isEmpty);
    });

    test('fromJson defensivo: JSON vazio retorna sessão corrupted', () {
      final session = ExposureSession.fromJson({});
      expect(session.id, anyOf(equals('unknown'), contains('corrupted')));
    });

    test('fromJson defensivo: readings com item inválido são ignorados', () {
      final json = {
        'id': 'test',
        'startTime': '2026-01-01T10:00:00.000',
        'spf': 30,
        'skinType': 'Tipo II - Clara',
        'maxExposurePercent': 50.0,
        'maxUVIndex': 7.0,
        'readings': [
          {'uvIndex': 5.0, 'timestamp': '2026-01-01T10:15:00.000'},
          {'invalid': 'data'},
          {'uvIndex': 7.0, 'timestamp': '2026-01-01T10:30:00.000'},
        ],
      };
      final session = ExposureSession.fromJson(json);
      expect(session.readings.length, equals(2));
    });
  });
}
