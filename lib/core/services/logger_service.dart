import 'package:flutter/foundation.dart';

/// Níveis de log do aplicativo
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Logger estruturado para o SunSense.
/// Centraliza logs com timestamp, nível e contexto,
/// substituindo chamadas dispersas de debugPrint.
class LoggerService {
  LoggerService._();

  static LogLevel _minLevel = LogLevel.debug;

  /// Define o nível mínimo de log (mensagens abaixo são ignoradas)
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log de nível debug (detalhes internos)
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Log de nível info (eventos operacionais normais)
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log de nível warning (situação inesperada, mas recuperável)
  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// Log de nível error (falha que requer atenção)
  static void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';

    final buffer = StringBuffer('$timestamp $levelStr $tagStr$message');

    if (error != null) {
      buffer.write(' | Erro: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    debugPrint(buffer.toString());
  }
}
