/// Strings do aplicativo SunSense centralizadas
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'SunSense';
  static const String appTitle = 'SUNSENSE';

  // Home Screen
  static const String spfLabel = 'Sun Protection Factor (SPF)';
  static const String skinTypeLabel = 'Skin Phototype';
  static const String startMonitoring = 'Start Monitoring';

  // Monitor Screen
  static const String elapsedTime = 'Elapsed Time';
  static const String safeExposureTime = 'Safe Exposure Time';
  static const String accumulatedExposure = 'Accumulated Exposure';
  static const String globalUVIndex = 'Global UV Index';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String confirmBackMessage = 'Monitoring will be restarted. Are you sure you want to go back?';

  // Connection Status
  static const String connected = 'Connected';
  static const String disconnected = 'Disconnected';
  static const String deviceNotFound = 'Device not found. Make sure you\'re connected to the same WiFi network as the SunSense device.';
  static const String retryConnection = 'Retry connection';

  // Skin Types
  static const List<String> skinTypes = [
    'Type 0 - Test',
    'Type I - Very Fair',
    'Type II - Fair',
    'Type III - Medium Fair',
    'Type IV - Medium Dark',
    'Type V - Dark',
    'Type VI - Very Dark',
  ];

  // SPF Values
  static const List<String> spfValues = ['15', '30', '50', '70'];

  // Notifications
  static const String notificationChannelId = 'uv_exposure_alerts';
  static const String notificationChannelName = 'UV Exposure Alerts';
  static const String notificationChannelDescription = 'Alerts for UV exposure levels';
  static const String exposureWarningTitle = 'UV Exposure Warning';
  static const String exposureCriticalTitle = 'UV Exposure Critical!';
  static const String exposureWarningBody = 'You have reached {percent}% of safe exposure time.';
  static const String exposureCriticalBody = 'Seek shade immediately! Maximum safe exposure reached.';

  // History
  static const String exposureHistory = 'Exposure History';
  static const String noHistoryData = 'No exposure data recorded yet.';
  static const String today = 'Today';
  static const String last7Days = 'Last 7 Days';
  static const String last30Days = 'Last 30 Days';
}
