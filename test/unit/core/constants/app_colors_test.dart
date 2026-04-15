import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:uv_exposure_app/core/constants/app_colors.dart';

void main() {
  // ─────────────────────────────────────────────
  // getUVIndexColor — Escala OMS completa
  // ─────────────────────────────────────────────
  group('AppColors.getUVIndexColor — escala OMS', () {
    test('UV 0 (baixo) deve retornar verde', () {
      expect(AppColors.getUVIndexColor(0), equals(AppColors.uvLow));
    });

    test('UV 1 (baixo) deve retornar verde', () {
      expect(AppColors.getUVIndexColor(1), equals(AppColors.uvLow));
    });

    test('UV 2 (baixo) deve retornar verde', () {
      expect(AppColors.getUVIndexColor(2), equals(AppColors.uvLow));
    });

    test('UV 3 (moderado) deve retornar amarelo', () {
      expect(AppColors.getUVIndexColor(3), equals(AppColors.uvModerate));
    });

    test('UV 5 (moderado) deve retornar amarelo', () {
      expect(AppColors.getUVIndexColor(5), equals(AppColors.uvModerate));
    });

    test('UV 6 (alto) deve retornar laranja', () {
      expect(AppColors.getUVIndexColor(6), equals(AppColors.uvHigh));
    });

    test('UV 7 (alto) deve retornar laranja', () {
      expect(AppColors.getUVIndexColor(7), equals(AppColors.uvHigh));
    });

    test('UV 8 (muito alto) deve retornar vermelho', () {
      expect(AppColors.getUVIndexColor(8), equals(AppColors.uvVeryHigh));
    });

    test('UV 10 (muito alto) deve retornar vermelho', () {
      expect(AppColors.getUVIndexColor(10), equals(AppColors.uvVeryHigh));
    });

    test('UV 11 (extremo) deve retornar roxo', () {
      expect(AppColors.getUVIndexColor(11), equals(AppColors.uvExtreme));
    });

    test('UV 15 (extremo) deve retornar roxo', () {
      expect(AppColors.getUVIndexColor(15), equals(AppColors.uvExtreme));
    });

    test('UV negativo deve retornar verde (baixo)', () {
      expect(AppColors.getUVIndexColor(-1), equals(AppColors.uvLow));
    });

    test('UV fracionário 2.5 (limiar) deve retornar moderado', () {
      expect(AppColors.getUVIndexColor(2.5), equals(AppColors.uvModerate));
    });

    test('UV fracionário 5.5 (limiar moderado-alto) deve retornar alto', () {
      expect(AppColors.getUVIndexColor(5.5), equals(AppColors.uvHigh));
    });
  });

  // ─────────────────────────────────────────────
  // getExposureColor — Gradiente de risco
  // ─────────────────────────────────────────────
  group('AppColors.getExposureColor — gradiente de risco', () {
    test('0% de exposição deve ser verde', () {
      final color = AppColors.getExposureColor(0);
      expect(color.toARGB32(), equals(AppColors.exposureSafe.toARGB32()));
    });

    test('50% de exposição deve ser amarelo', () {
      final color = AppColors.getExposureColor(50);
      expect(color.toARGB32(), equals(AppColors.exposureWarning.toARGB32()));
    });

    test('100% de exposição deve ser vermelho', () {
      final color = AppColors.getExposureColor(100);
      expect(color.toARGB32(), equals(AppColors.exposureDanger.toARGB32()));
    });

    test('25% deve estar entre verde e amarelo', () {
      final color = AppColors.getExposureColor(25);
      // Componente verde deve ser forte, vermelho moderado
      expect((color.g * 255).round(), greaterThan(0));
    });

    test('75% deve estar entre amarelo e vermelho', () {
      final color = AppColors.getExposureColor(75);
      // Componente vermelho deve ser dominante
      expect((color.r * 255).round(), greaterThan((color.b * 255).round()));
    });

    test('exposição progressiva deve transicionar verde→amarelo→vermelho', () {
      final c0 = AppColors.getExposureColor(0); // verde
      final c50 = AppColors.getExposureColor(50); // amarelo
      final c100 = AppColors.getExposureColor(100); // vermelho

      // Verde → Amarelo: componente vermelho deve aumentar
      expect((c50.r * 255).round(), greaterThan((c0.r * 255).round()),
          reason: 'Vermelho deve crescer de verde para amarelo');
      // Amarelo → Vermelho: componente verde deve diminuir
      expect((c100.g * 255).round(), lessThan((c50.g * 255).round()),
          reason: 'Verde deve diminuir de amarelo para vermelho');
    });

    test('deve retornar cores não nulas para qualquer porcentagem válida', () {
      for (int i = 0; i <= 100; i += 5) {
        final color = AppColors.getExposureColor(i.toDouble());
        expect(color, isNotNull);
      }
    });
  });

  // ─────────────────────────────────────────────
  // Constantes de cor
  // ─────────────────────────────────────────────
  group('AppColors — constantes de cor', () {
    test('cor primária deve ser amarelo (#FFCE26)', () {
      expect(AppColors.primary, equals(const Color(0xFFFFCE26)));
    });

    test('cor secundária deve ser roxo (#77347A)', () {
      expect(AppColors.secondary, equals(const Color(0xFF77347A)));
    });

    test('cores de conexão devem estar definidas', () {
      expect(AppColors.connected, equals(Colors.green));
      expect(AppColors.disconnected, equals(Colors.red));
    });

    test('cores de exposição devem seguir semáforo', () {
      expect(AppColors.exposureSafe, equals(Colors.green));
      expect(AppColors.exposureWarning, equals(Colors.yellow));
      expect(AppColors.exposureDanger, equals(Colors.red));
    });
  });
}
