import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../models/exposure_model.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

/// Provider para gerenciar o histórico de sessões de exposição UV
class HistoryProvider extends ChangeNotifier {
  List<ExposureSession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  // Getters públicos
  List<ExposureSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _sessions.isNotEmpty;

  /// Carrega todo o histórico de sessões
  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await StorageService.getExposureHistory();
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      _error = '${AppStrings.failedToLoadHistory}: $e';
      LoggerService.error(_error!, tag: 'HistoryProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega sessões realizadas hoje
  Future<void> loadTodaySessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await StorageService.getTodaySessions();
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      _error = '${AppStrings.failedToLoadSessions}: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega sessões dos últimos N dias
  Future<void> loadSessionsLastDays(int days) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await StorageService.getSessionsLastDays(days);
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      _error = '${AppStrings.failedToLoadSessions}: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calcula estatísticas do período carregado
  Map<String, dynamic> getStatistics() {
    if (_sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalDuration': Duration.zero,
        'averageExposure': 0.0,
        'maxExposure': 0.0,
        'averageUVIndex': 0.0,
        'maxUVIndex': 0.0,
      };
    }

    Duration totalDuration = Duration.zero;
    double totalExposure = 0;
    double maxExposure = 0;
    double totalUVIndex = 0;
    double maxUVIndex = 0;

    for (final session in _sessions) {
      totalDuration += session.duration;
      totalExposure +=
          session.averageExposurePercent * session.duration.inSeconds;
      totalUVIndex += session.maxUVIndex;

      if (session.maxExposurePercent > maxExposure) {
        maxExposure = session.maxExposurePercent;
      }
      if (session.maxUVIndex > maxUVIndex) {
        maxUVIndex = session.maxUVIndex;
      }
    }

    return {
      'totalSessions': _sessions.length,
      'totalDuration': totalDuration,
      'averageExposure': totalDuration.inSeconds > 0
          ? totalExposure / totalDuration.inSeconds
          : 0.0,
      'maxExposure': maxExposure,
      'averageUVIndex': totalUVIndex / _sessions.length,
      'maxUVIndex': maxUVIndex,
    };
  }

  /// Retorna dados agregados por dia para o gráfico
  List<Map<String, dynamic>> getDailyExposureData(int days) {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final daySessions = _sessions.where((s) =>
          s.startTime.isAfter(startOfDay) && s.startTime.isBefore(endOfDay));

      double weightedExposureSum = 0;
      double maxUV = 0;
      Duration totalDuration = Duration.zero;

      for (final session in daySessions) {
        weightedExposureSum +=
            session.averageExposurePercent * session.duration.inSeconds;
        if (session.maxUVIndex > maxUV) maxUV = session.maxUVIndex;
        totalDuration += session.duration;
      }

      data.add({
        'date': startOfDay,
        'exposure': totalDuration.inSeconds > 0
            ? weightedExposureSum / totalDuration.inSeconds
            : 0.0,
        'maxUVIndex': maxUV,
        'duration': totalDuration,
        'sessions': daySessions.length,
      });
    }

    return data;
  }

  /// Limpa todo o histórico de sessões
  Future<void> clearHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.clearHistory();
      _sessions = [];
    } catch (e) {
      _error = '${AppStrings.failedToLoadHistory}: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
