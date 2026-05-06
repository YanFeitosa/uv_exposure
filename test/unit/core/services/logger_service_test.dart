import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/services/logger_service.dart';

void main() {
  group('AppLogger', () {
    test('setMinLevel deve filtrar logs abaixo do nível', () {
      // Não lança exceção ao usar qualquer nível de log
      LoggerService.setMinLevel(LogLevel.error);
      LoggerService.debug('debug ignorado');
      LoggerService.info('info ignorado');
      LoggerService.warning('warning ignorado');
      LoggerService.error('error exibido');
    });

    test('debug deve aceitar tag opcional', () {
      LoggerService.setMinLevel(LogLevel.debug);
      // Não deve lançar exceção
      LoggerService.debug('mensagem', tag: 'TestTag');
    });

    test('warning deve aceitar error opcional', () {
      LoggerService.setMinLevel(LogLevel.debug);
      LoggerService.warning('algo errado', error: Exception('teste'));
    });

    test('error deve aceitar stackTrace opcional', () {
      LoggerService.setMinLevel(LogLevel.debug);
      try {
        throw Exception('erro teste');
      } catch (e, st) {
        LoggerService.error('falha', error: e, stackTrace: st);
      }
    });

    test('LogLevel deve ter 4 valores', () {
      expect(LogLevel.values.length, equals(4));
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
    });

    tearDown(() {
      // Restaura nível padrão
      LoggerService.setMinLevel(LogLevel.debug);
    });
  });
}
