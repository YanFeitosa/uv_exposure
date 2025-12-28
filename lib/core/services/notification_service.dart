import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_strings.dart';

/// Serviço para gerenciar notificações locais
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static bool _permissionGranted = false;

  /// Verifica se as notificações estão habilitadas
  static bool get isEnabled => _isInitialized && _permissionGranted;
  
  /// Verifica se está em uma plataforma suportada
  static bool get _isSupported => !kIsWeb;

  /// Inicializa o serviço de notificações
  static Future<bool> init() async {
    // Não inicializa no web
    if (!_isSupported) return false;
    
    if (_isInitialized) return true;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

      // Cria o canal de notificação para Android
      await _createNotificationChannel();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
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
    debugPrint('Notification tapped: ${response.payload}');
    // Pode ser usado para navegação quando o usuário toca na notificação
  }

  /// Solicita permissão para notificações
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    
    // Garante que o serviço está inicializado
    if (!_isInitialized) {
      final initialized = await init();
      if (!initialized) return false;
    }
    
    try {
      bool granted = false;
      
      // Android 13+ (API 33) requer permissão explícita
      if (!kIsWeb && Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (android != null) {
          // Verifica se já tem permissão
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
      // Outras plataformas (macOS, Linux, etc.)
      else {
        granted = true;
      }
      
      _permissionGranted = granted;
      debugPrint('NotificationService: permissão ${granted ? "concedida" : "negada"}');
      return granted;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
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

  /// Mostra notificação de aviso de exposição (75%)
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
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFCE26),
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
      1, // Warning notification ID
      AppStrings.exposureWarningTitle,
      body,
      details,
      payload: 'exposure_warning',
    );
  }

  /// Mostra notificação crítica de exposição (100%)
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
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF0000),
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
      2, // Critical notification ID
      AppStrings.exposureCriticalTitle,
      AppStrings.exposureCriticalBody,
      details,
      payload: 'exposure_critical',
    );
  }

  /// Cancela todas as notificações
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancela uma notificação específica
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
