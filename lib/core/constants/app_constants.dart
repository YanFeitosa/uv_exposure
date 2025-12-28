/// Constantes do aplicativo SunSense
class AppConstants {
  AppConstants._();

  // URLs e Endpoints
  static const String deviceBaseUrl = 'http://sunsense.local';
  static const String deviceDataEndpoint = '/data';
  static const String deviceFallbackIp = '192.168.1.100'; // IP fallback

  // Timeouts
  static const Duration httpTimeout = Duration(seconds: 10);
  static const Duration connectionCheckTimeout = Duration(seconds: 5);
  static const Duration dataFetchInterval = Duration(seconds: 5); // Intervalo entre requisições
  static const Duration cacheIndicatorThreshold = Duration(seconds: 15); // 3 falhas antes de mostrar indicador de cache

  // TEP (Tempo de Eritema Pele) por tipo de pele em minutos
  static const Map<String, double> tepBySkinType = {
    'Type 0 - Demo': 0.1,
    'Type I - Very Fair': 7.5,
    'Type II - Fair': 15.0,
    'Type III - Medium Fair': 25.0,
    'Type IV - Medium Dark': 35.0,
    'Type V - Dark': 50.0,
    'Type VI - Very Dark': 75.0,
  };

  // SPF disponíveis
  static const List<double> availableSpfValues = [15, 30, 50, 70];

  // Limites de exposição
  static const double exposureWarningThreshold = 75.0;
  static const double exposureCriticalThreshold = 100.0;

  // Notificações
  static const int notificationWarningId = 1;
  static const int notificationCriticalId = 2;

  // Cache
  static const String cacheKeyLastUVData = 'last_uv_data';
  static const String cacheKeyExposureHistory = 'exposure_history';
  static const String cacheKeyLastSession = 'last_session';
  static const Duration cacheExpiration = Duration(minutes: 5);

  // Histórico
  static const int maxHistoryEntries = 1000;
}
