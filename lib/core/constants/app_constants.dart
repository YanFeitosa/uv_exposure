class AppConstants {
  AppConstants._();

  // URLs e Endpoints
  static const String deviceBaseUrl = 'http://sunsense.local';
  static const String deviceDataEndpoint = '/data';
  static const String deviceFallbackIp = '192.168.1.100';

  // Timeouts e intervalos de rede
  static const Duration httpTimeout = Duration(seconds: 10);
  static const Duration connectionCheckTimeout = Duration(seconds: 5);
  static const Duration dataFetchInterval = Duration(seconds: 5);
  static const Duration cacheIndicatorThreshold = Duration(seconds: 15);

  // TEP (Tempo de Eritema Pele) por fototipo em minutos
  static const Map<String, double> tepBySkinType = {
    'Tipo 0 - Demo': 0.1,
    'Tipo I - Muito Clara': 7.5,
    'Tipo II - Clara': 15.0,
    'Tipo III - Média Clara': 25.0,
    'Tipo IV - Média Escura': 35.0,
    'Tipo V - Escura': 50.0,
    'Tipo VI - Muito Escura': 75.0,
  };

  // Valores de SPF disponíveis (0 = sem protetor)
  static const List<double> availableSpfValues = [0, 15, 30, 50, 70];

  // Limites de exposição (%)
  static const double exposureWarningThreshold = 75.0;
  static const double exposureCriticalThreshold = 100.0;

  // IDs de notificação
  static const int notificationWarningId = 1;
  static const int notificationCriticalId = 2;
  static const int notificationCacheId = 3;
  static const int notificationStoppedId = 4;
  static const int notificationGapId = 5;
  static const String notificationWarningPayload = 'exposure_warning';
  static const String notificationCriticalPayload = 'exposure_critical';
  static const String notificationCachePayload = 'cache_warning';
  static const String notificationStoppedPayload = 'monitoring_stopped';
  static const String notificationGapPayload = 'gap_compensation';

  // Chaves de cache e armazenamento
  static const String cacheKeyLastUVData = 'last_uv_data';
  static const String cacheKeyExposureHistory = 'exposure_history';
  static const String cacheKeyLastSession = 'last_session';
  static const String cacheKeyDefaultSpf = 'user_default_spf';
  static const String cacheKeyDefaultSkinType = 'user_default_skin_type';
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const String cacheKeyNotificationPermission =
      'notification_permission_asked';
  static const String cacheKeyDemoMode = 'demo_mode_enabled';
  static const String cacheKeySoundAlarm = 'sound_alarm_enabled';

  // Valores padrão
  static const double defaultUVIndex = 1.0;
  static const double defaultTEP = 15.0;
  static const double minExposureThreshold = 0.0001;
  static const int saveProgressInterval = 30;

  // Modo Demo
  static const int demoUVCyclePeriod = 120;
  static const double demoUVCenter = 6.0;
  static const double demoUVAmplitude = 5.0;

  // Assets
  static const String imageAssetPath = 'assets/images/image.png';
  static const String alarmAssetPath = 'audio/alarm.mp3';

  // Histórico
  static const int maxHistoryEntries = 1000;

  // Compensação de gap (suspensão do sistema)
  static const int maxGapSimulationSeconds = 1200;
  static const int gapDetectionThresholdSeconds = 2;

  // Foreground Service
  static const String foregroundChannelId = 'sunsense_monitoring';
  static const String foregroundChannelName = 'Monitoramento SunSense';
  static const String foregroundChannelDescription =
      'Monitoramento de exposição UV em segundo plano';
}
