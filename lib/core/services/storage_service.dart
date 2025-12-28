import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/exposure_model.dart';

/// Serviço para persistência de dados locais
class StorageService {
  static SharedPreferences? _prefs;

  /// Inicializa o serviço de storage
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Garante que o serviço está inicializado
  static Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ========== Última sessão ==========

  /// Salva os dados da última sessão
  static Future<void> saveLastSession({
    required double spf,
    required String skinType,
    required double accumulatedExposure,
    required int secondsElapsed,
  }) async {
    final prefs = await _preferences;
    final data = {
      'spf': spf,
      'skinType': skinType,
      'accumulatedExposure': accumulatedExposure,
      'secondsElapsed': secondsElapsed,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(AppConstants.cacheKeyLastSession, jsonEncode(data));
  }

  /// Recupera os dados da última sessão
  static Future<Map<String, dynamic>?> getLastSession() async {
    final prefs = await _preferences;
    final data = prefs.getString(AppConstants.cacheKeyLastSession);
    if (data == null) return null;
    
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Limpa a última sessão
  static Future<void> clearLastSession() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.cacheKeyLastSession);
  }

  // ========== Histórico de exposição ==========

  /// Salva uma sessão no histórico
  static Future<void> saveExposureSession(ExposureSession session) async {
    final prefs = await _preferences;
    final history = await getExposureHistory();
    
    // Remove sessões antigas se exceder o limite
    while (history.length >= AppConstants.maxHistoryEntries) {
      history.removeAt(0);
    }
    
    history.add(session);
    
    final data = history.map((s) => s.toJson()).toList();
    await prefs.setString(AppConstants.cacheKeyExposureHistory, jsonEncode(data));
  }

  /// Recupera o histórico de exposição
  static Future<List<ExposureSession>> getExposureHistory() async {
    final prefs = await _preferences;
    final data = prefs.getString(AppConstants.cacheKeyExposureHistory);
    if (data == null) return [];
    
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((item) => ExposureSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Recupera sessões de um período específico
  static Future<List<ExposureSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final history = await getExposureHistory();
    return history.where((session) {
      return session.startTime.isAfter(start) && session.startTime.isBefore(end);
    }).toList();
  }

  /// Recupera sessões de hoje
  static Future<List<ExposureSession>> getTodaySessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSessionsInRange(startOfDay, endOfDay);
  }

  /// Recupera sessões dos últimos N dias
  static Future<List<ExposureSession>> getSessionsLastDays(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    return getSessionsInRange(start, now);
  }

  /// Limpa todo o histórico
  static Future<void> clearHistory() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.cacheKeyExposureHistory);
  }

  // ========== Cache de dados UV ==========

  /// Salva os últimos dados UV
  static Future<void> cacheUVData(double uvIndex) async {
    final prefs = await _preferences;
    final data = {
      'uvIndex': uvIndex,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(AppConstants.cacheKeyLastUVData, jsonEncode(data));
  }

  /// Recupera os dados UV do cache
  static Future<Map<String, dynamic>?> getCachedUVData() async {
    final prefs = await _preferences;
    final data = prefs.getString(AppConstants.cacheKeyLastUVData);
    if (data == null) return null;
    
    try {
      final parsed = jsonDecode(data) as Map<String, dynamic>;
      final timestamp = DateTime.parse(parsed['timestamp'] as String);
      final age = DateTime.now().difference(timestamp);
      
      // Retorna null se o cache expirou
      if (age > AppConstants.cacheExpiration) {
        return null;
      }
      
      return parsed;
    } catch (_) {
      return null;
    }
  }

  // ========== Configurações do usuário ==========

  /// Salva as preferências do usuário
  static Future<void> saveUserPreferences({
    String? defaultSpf,
    String? defaultSkinType,
  }) async {
    final prefs = await _preferences;
    if (defaultSpf != null) {
      await prefs.setString('user_default_spf', defaultSpf);
    }
    if (defaultSkinType != null) {
      await prefs.setString('user_default_skin_type', defaultSkinType);
    }
  }

  /// Recupera as preferências do usuário
  static Future<Map<String, String?>> getUserPreferences() async {
    final prefs = await _preferences;
    return {
      'defaultSpf': prefs.getString('user_default_spf'),
      'defaultSkinType': prefs.getString('user_default_skin_type'),
    };
  }

  // ========== Permissões ==========

  static const String _notificationPermissionAskedKey = 'notification_permission_asked';

  /// Verifica se já perguntamos ao usuário sobre permissão de notificação
  static Future<bool> wasNotificationPermissionAsked() async {
    final prefs = await _preferences;
    return prefs.getBool(_notificationPermissionAskedKey) ?? false;
  }

  /// Marca que já perguntamos ao usuário sobre permissão de notificação
  static Future<void> setNotificationPermissionAsked() async {
    final prefs = await _preferences;
    await prefs.setBool(_notificationPermissionAskedKey, true);
  }

  /// Reseta o estado de pergunta (útil para debug ou se quiser perguntar novamente)
  static Future<void> resetNotificationPermissionAsked() async {
    final prefs = await _preferences;
    await prefs.remove(_notificationPermissionAskedKey);
  }
}
