import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

/// Serviço para gerenciar notificações locais
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static bool _permissionGranted = false;

  /// Verifica se as notificações estão habilitadas
  static bool get isEnabled => _isInitialized && _permissionGranted;
  
  /// Verifica se está em plataforma suportada (não-web)
  static bool get _isSupported => !kIsWeb;

  /// Inicializa o serviço de notificações
  static Future<bool> init() async {
    // Não inicializa em plataforma web
    if (!_isSupported) return false;
    
    if (_isInitialized) return true;

    try {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (initialized != true) {
        debugPrint('NotificationService: falha na inicialização');
        return false;
      }

      // Cria canal de notificação Android (obrigatório para Android 8+)
      await _createNotificationChannel();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('NotificationService: erro na inicialização: $e');
      return false;
    }
  }

  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      AppStrings.notificationChannelId,
      AppStrings.notificationChannelName,
      description: AppStrings.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificação tocada: ${response.payload}');
    // Pode ser usado para navegação ao tocar na notificação
  }

  /// Solicita permissão para enviar notificações
  static Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    
    if (!_isInitialized) {
      final initialized = await init();
      if (!initialized) return false;
    }
    
    try {
      bool granted = false;
      
      // Android 13+ requer permissão explícita
      if (!kIsWeb && Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (android != null) {
          final areEnabled = await android.areNotificationsEnabled();
          if (areEnabled == true) {
            _permissionGranted = true;
            return true;
          }
          
          // Solicita permissão
          granted = await android.requestNotificationsPermission() ?? false;
        }
      }
      // iOS
      else if (!kIsWeb && Platform.isIOS) {
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (ios != null) {
          granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
        }
      }
      // Outras plataformas — permissão assumida
      else {
        granted = true;
      }
      
      _permissionGranted = granted;
      debugPrint('NotificationService: permissão ${granted ? "concedida" : "negada"}');
      return granted;
    } catch (e) {
      debugPrint('NotificationService: erro ao solicitar permissão: $e');
      return false;
    }
  }
  
  /// Verifica se as notificações estão habilitadas no sistema
  static Future<bool> areNotificationsEnabled() async {
    if (!_isSupported || !_isInitialized) return false;
    
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      return _permissionGranted;
    } catch (e) {
      return false;
    }
  }

  /// Exibe notificação de aviso de exposição UV (75%)
  static Future<void> showExposureWarning(double percent) async {
    if (!_isSupported) return;
    if (!_isInitialized) await init();
    if (!_isInitialized || !_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      AppStrings.notificationChannelId,
      AppStrings.notificationChannelName,
      channelDescription: AppStrings.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: AppColors.uvHigh,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = AppStrings.exposureWarningBody.replaceAll(
      '{percent}',
      percent.toStringAsFixed(0),
    );

    await _notifications.show(
      AppConstants.notificationWarningId,
      AppStrings.exposureWarningTitle,
      body,
      details,
      payload: AppConstants.notificationWarningPayload,
    );
  }

  /// Exibe notificação crítica de exposição UV (100%)
  static Future<void> showExposureCritical() async {
    if (!_isSupported) return;
    if (!_isInitialized) await init();
    if (!_isInitialized || !_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      AppStrings.notificationChannelId,
      AppStrings.notificationChannelName,
      channelDescription: AppStrings.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@drawable/ic_notification',
      color: AppColors.notificationCritical,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.notificationCriticalId,
      AppStrings.exposureCriticalTitle,
      AppStrings.exposureCriticalBody,
      details,
      payload: AppConstants.notificationCriticalPayload,
    );
  }

  /// Exibe notificação de perda de conexão com o sensor
  static Future<void> showCacheWarning() async {
    if (!_isSupported) return;
    if (!_isInitialized) await init();
    if (!_isInitialized || !_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      AppStrings.notificationChannelId,
      AppStrings.notificationChannelName,
      channelDescription: AppStrings.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: AppColors.primary,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.notificationCacheId,
      AppStrings.cacheNotificationTitle,
      AppStrings.cacheNotificationBody,
      details,
      payload: AppConstants.notificationCachePayload,
    );
  }

  /// Exibe notificação de parada por desconexão prolongada
  static Future<void> showMonitoringStopped() async {
    if (!_isSupported) return;
    if (!_isInitialized) await init();
    if (!_isInitialized || !_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      AppStrings.notificationChannelId,
      AppStrings.notificationChannelName,
      channelDescription: AppStrings.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@drawable/ic_notification',
      color: AppColors.notificationCritical,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = AppStrings.stoppedNotificationBody.replaceAll(
      '{minutes}',
      '${AppConstants.cacheExpiration.inMinutes}',
    );

    await _notifications.show(
      AppConstants.notificationStoppedId,
      AppStrings.stoppedNotificationTitle,
      body,
      details,
      payload: AppConstants.notificationStoppedPayload,
    );
  }

  /// Exibe notificação de exposição simulada durante gap do sistema
  static Future<void> showGapWarning({
    required int gapSeconds,
    required int compensatedSeconds,
    required double uvIndex,
  }) async {
    if (!_isSupported) return;
    if (!_isInitialized) await init();
    if (!_isInitialized || !_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      AppStrings.notificationChannelId,
      AppStrings.notificationChannelName,
      channelDescription: AppStrings.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: AppColors.primary,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final minutes = gapSeconds ~/ 60;
    final seconds = gapSeconds % 60;
    final durationStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    final body = AppStrings.gapNotificationBody.replaceAll('{minutes}', durationStr);

    await _notifications.show(
      AppConstants.notificationGapId,
      AppStrings.gapNotificationTitle,
      body,
      details,
      payload: AppConstants.notificationGapPayload,
    );
  }

  /// Cancela todas as notificações ativas
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancela uma notificação específica pelo ID
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
