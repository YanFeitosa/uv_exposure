import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import 'logger_service.dart';

/// Wrapper para o Android Foreground Service.
/// Mantém o processo do app vivo em segundo plano.
class ForegroundService {
  static bool _isInitialized = false;

  /// Verifica se a plataforma suporta foreground service (Android apenas)
  static bool get _isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Inicializa a configuração do Foreground Service
  static void init() {
    if (!_isSupported) return;
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConstants.foregroundChannelId,
        channelName: AppConstants.foregroundChannelName,
        channelDescription: AppConstants.foregroundChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: true,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
    AppLogger.info('Inicializado', tag: 'ForegroundService');
  }

  /// Inicia o Foreground Service com notificação persistente
  static Future<void> start() async {
    if (!_isSupported) return;
    if (!_isInitialized) init();

    try {
      if (await FlutterForegroundTask.isRunningService) return;

      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: AppStrings.appName,
        notificationText: AppStrings.foregroundNotificationInitial,
        serviceTypes: [ForegroundServiceTypes.connectedDevice],
        callback: _startCallback,
      );

      AppLogger.info('start result = $result', tag: 'ForegroundService');
    } catch (e) {
      AppLogger.error('Erro ao iniciar serviço',
          tag: 'ForegroundService', error: e);
    }
  }

  /// Atualiza a notificação persistente com o progresso atual
  static Future<void> updateProgress(double percent, String timeElapsed) async {
    if (!_isSupported) return;

    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) return;

      final text = AppStrings.foregroundNotificationText
          .replaceAll('{percent}', percent.toStringAsFixed(1))
          .replaceAll('{time}', timeElapsed);

      await FlutterForegroundTask.updateService(
        notificationTitle: AppStrings.foregroundNotificationTitle,
        notificationText: text,
      );
    } catch (e) {
      // Silencia erros de atualização
      AppLogger.warning('Erro ao atualizar notificação',
          tag: 'ForegroundService', error: e);
    }
  }

  /// Para o Foreground Service
  static Future<void> stop() async {
    if (!_isSupported) return;

    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) return;

      await FlutterForegroundTask.stopService();
      AppLogger.info('Serviço parado', tag: 'ForegroundService');
    } catch (e) {
      AppLogger.error('Erro ao parar serviço',
          tag: 'ForegroundService', error: e);
    }
  }

  /// Verifica se a economia de bateria está desativada para o app
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_isSupported) return true;
    try {
      return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (e) {
      return false;
    }
  }

  /// Solicita desativação da economia de bateria para o app
  static Future<bool> requestIgnoreBatteryOptimization() async {
    if (!_isSupported) return false;
    try {
      return await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (e) {
      AppLogger.error('Erro ao solicitar economia de bateria',
          tag: 'ForegroundService', error: e);
      return false;
    }
  }

  /// Abre as configurações de economia de bateria do sistema
  static Future<bool> openBatteryOptimizationSettings() async {
    if (!_isSupported) return false;
    try {
      return await FlutterForegroundTask
          .openIgnoreBatteryOptimizationSettings();
    } catch (e) {
      AppLogger.error('Erro ao abrir configurações',
          tag: 'ForegroundService', error: e);
      return false;
    }
  }
}

/// Callback executado quando o foreground service inicia
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_NoOpTaskHandler());
}

/// TaskHandler vazio — apenas mantém o processo vivo
class _NoOpTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.info('TaskHandler: onStart', tag: 'ForegroundService');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    AppLogger.info('TaskHandler: onDestroy (isTimeout: $isTimeout)',
        tag: 'ForegroundService');
  }
}
