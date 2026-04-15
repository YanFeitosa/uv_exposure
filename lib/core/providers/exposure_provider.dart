import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/exposure_model.dart';
import '../services/logger_service.dart';
import '../services/uv_data_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/foreground_service.dart';

/// Estados de conexão com o dispositivo IoT
enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  usingCache,
}

/// Provider principal: gerencia o estado do monitoramento de exposição UV
class ExposureProvider extends ChangeNotifier {
  // Configurações do usuário
  late double _spf;
  late String _skinType;
  late ExposureModel _model;
  
  // Estado do monitoramento
  bool _isMonitoring = false;
  int _secondsElapsed = 0;
  double _currentUVIndex = 1.0;
  Timer? _timer;
  
  // Estado da conexão com o dispositivo
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _connectionError;
  DateTime? _disconnectedSince;
  bool _stoppedDueToDisconnection = false;
  
  // Alarme sonoro
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _alarmPlayed = false;
  bool _alarmActive = false;
  bool _warningNotificationSent = false;
  bool _cacheNotificationSent = false;
  
  // Controle de requisições HTTP
  bool _isFetching = false;
  
  // Modo Demo (dados UV simulados, sem HTTP)
  bool _isDemoMode = false;
  
  // Detecção de gap (suspensão do sistema)
  DateTime? _lastTickTime;
  bool _gapDetected = false;
  int _lastGapDurationSeconds = 0;
  int _lastGapCompensatedSeconds = 0;
  bool _gapExceededMax = false;
  bool _gapDismissed = false;
  double _gapUVIndex = 0.0;
  
  // Dados da sessão atual
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  List<UVReading> _sessionReadings = [];
  double _maxUVIndex = 0.0;

  // Getters públicos
  bool get isMonitoring => _isMonitoring;
  int get secondsElapsed => _secondsElapsed;
  double get currentUVIndex => _currentUVIndex;
  double get spf => _spf;
  String get skinType => _skinType;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get connectionError => _connectionError;
  bool get alarmPlayed => _alarmPlayed;
  bool get alarmActive => _alarmActive;
  bool get stoppedDueToDisconnection => _stoppedDueToDisconnection;
  bool get isDemoMode => _isDemoMode;
  
  bool get gapDetected => _gapDetected;
  int get lastGapDurationSeconds => _lastGapDurationSeconds;
  int get lastGapCompensatedSeconds => _lastGapCompensatedSeconds;
  bool get gapExceededMax => _gapExceededMax;
  bool get gapDismissed => _gapDismissed;
  double get gapUVIndex => _gapUVIndex;
  
  /// Sinaliza que o usuário viu e dispensou o aviso de gap
  void dismissGapWarning() {
    _gapDismissed = true;
    notifyListeners();
  }

  /// Configura estado interno para testes de widget.
  @visibleForTesting
  void setTestState({
    ConnectionStatus? connectionStatus,
    String? connectionError,
    bool? stoppedDueToDisconnection,
    bool? gapDetected,
    int? lastGapDurationSeconds,
    int? lastGapCompensatedSeconds,
    bool? gapExceededMax,
    double? gapUVIndex,
    bool? alarmActive,
    double? currentUVIndex,
    bool? isMonitoring,
    int? secondsElapsed,
    bool? gapDismissed,
    DateTime? disconnectedSince,
  }) {
    if (connectionStatus != null) _connectionStatus = connectionStatus;
    if (connectionError != null) _connectionError = connectionError;
    if (stoppedDueToDisconnection != null) _stoppedDueToDisconnection = stoppedDueToDisconnection;
    if (gapDetected != null) _gapDetected = gapDetected;
    if (lastGapDurationSeconds != null) _lastGapDurationSeconds = lastGapDurationSeconds;
    if (lastGapCompensatedSeconds != null) _lastGapCompensatedSeconds = lastGapCompensatedSeconds;
    if (gapExceededMax != null) _gapExceededMax = gapExceededMax;
    if (gapUVIndex != null) _gapUVIndex = gapUVIndex;
    if (alarmActive != null) _alarmActive = alarmActive;
    if (currentUVIndex != null) _currentUVIndex = currentUVIndex;
    if (isMonitoring != null) _isMonitoring = isMonitoring;
    if (secondsElapsed != null) _secondsElapsed = secondsElapsed;
    if (gapDismissed != null) _gapDismissed = gapDismissed;
    if (disconnectedSince != null) _disconnectedSince = disconnectedSince;
    notifyListeners();
  }
  
  /// Ativa ou desativa o modo Demo (deve ser chamado antes de startMonitoring)
  void setDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }
  
  /// Retorna se deve mostrar o indicador de cache
  bool get shouldShowCacheIndicator {
    if (_disconnectedSince == null) return false;
    return secondsDisconnected >= AppConstants.cacheIndicatorThreshold.inSeconds;
  }
  
  /// Retorna há quantos segundos está desconectado
  int get secondsDisconnected {
    if (_disconnectedSince == null) return 0;
    return DateTime.now().difference(_disconnectedSince!).inSeconds;
  }
  
  /// Retorna o tempo restante de cache em segundos
  int get cacheTimeRemaining {
    if (_disconnectedSince == null) return AppConstants.cacheExpiration.inSeconds;
    final elapsed = DateTime.now().difference(_disconnectedSince!).inSeconds;
    final remaining = AppConstants.cacheExpiration.inSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
  
  double get accumulatedExposurePercent => _model.accumulatedExposurePercent;
  bool get isCritical => _model.isCritical;
  bool get isWarning => _model.isWarning;

  int get initialSafeExposureTime => 
      _model.calculateInitialSafeExposureTime(_currentUVIndex);
  
  int get remainingSafeExposureTime {
    final remaining = _model.calculateRemainingSafeTime(_secondsElapsed);
    return remaining > 0 ? remaining : 0;
  }

  /// Inicializa o provider com as configurações do usuário
  void initialize({required double spf, required String skinType}) {
    _spf = spf;
    _skinType = skinType;
    _model = ExposureModel(spf: spf, skinType: skinType);
    _resetState();
  }

  void _resetState() {
    _secondsElapsed = 0;
    _currentUVIndex = AppConstants.defaultUVIndex;
    _alarmPlayed = false;
    _alarmActive = false;
    _warningNotificationSent = false;
    _cacheNotificationSent = false;
    _connectionError = null;
    _disconnectedSince = null;
    _stoppedDueToDisconnection = false;
    _sessionReadings = [];
    _maxUVIndex = 0.0;
    _lastTickTime = null;
    _gapDetected = false;
    _lastGapDurationSeconds = 0;
    _lastGapCompensatedSeconds = 0;
    _gapExceededMax = false;
    _gapDismissed = false;
    _gapUVIndex = 0.0;
    _model.reset();
  }

  /// Inicia o monitoramento de exposição UV
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _resetState();
    _isMonitoring = true;
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
    
    await _checkConnection();
    
    // Inicia o Foreground Service (Android) para manter o app vivo
    await ForegroundService.start();
    
    // Timer principal (1 segundo)
    _lastTickTime = DateTime.now();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
    
    notifyListeners();
  }

  /// Para o monitoramento e salva a sessão no histórico
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;

    // Para o alarme se estiver tocando
    if (_alarmActive) {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      _alarmActive = false;
    }

    // Para o Foreground Service
    await ForegroundService.stop();
    await _saveSession();
    
    notifyListeners();
  }

  /// Pausa o monitoramento temporariamente
  void pauseMonitoring() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Retoma o monitoramento
  void resumeMonitoring() {
    if (!_isMonitoring || _timer != null) return;
    
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
    notifyListeners();
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    
    // Compensação de gap (suspensão do sistema)
    if (_lastTickTime != null) {
      final elapsedSinceLastTick = now.difference(_lastTickTime!).inSeconds;
      if (elapsedSinceLastTick > AppConstants.gapDetectionThresholdSeconds) {
        final missedSeconds = elapsedSinceLastTick - 1;
        await _compensateGap(missedSeconds);
      }
    }
    _lastTickTime = now;
    
    // Acumula exposição UV
    _secondsElapsed++;
    _model.accumulateExposure(_currentUVIndex, 1);
    
    // Busca dados UV do sensor periodicamente
    if (_secondsElapsed % AppConstants.dataFetchInterval.inSeconds == 0) {
      await _fetchUVData();
      
      // Registra leitura na sessão e atualiza o UV máximo
      _sessionReadings.add(UVReading(
        uvIndex: _currentUVIndex,
        timestamp: DateTime.now(),
      ));
      if (_currentUVIndex > _maxUVIndex) {
        _maxUVIndex = _currentUVIndex;
      }
    }
    
    await _checkExposureLimits();
    
    // Salva progresso periodicamente (a cada 30 segundos)
    if (_secondsElapsed % AppConstants.saveProgressInterval == 0) {
      await _saveProgress();
    }
    
    // Atualiza notificação do Foreground Service
    await ForegroundService.updateProgress(
      _model.accumulatedExposurePercent,
      formatTime(_secondsElapsed),
    );
    
    notifyListeners();
  }

  /// Compensa exposição perdida durante suspensão do sistema
  Future<void> _compensateGap(int missedSeconds) async {
    final maxGap = AppConstants.maxGapSimulationSeconds;
    final compensatedSeconds = missedSeconds.clamp(0, maxGap);
    
    _model.accumulateExposure(_currentUVIndex, compensatedSeconds);
    _secondsElapsed += compensatedSeconds;
    
    // Registra estado do gap para a UI
    _gapDetected = true;
    _gapDismissed = false;
    _lastGapDurationSeconds = missedSeconds;
    _lastGapCompensatedSeconds = compensatedSeconds;
    _gapExceededMax = missedSeconds > maxGap;
    _gapUVIndex = _currentUVIndex;
    
    AppLogger.info(
      'Gap detectado: ${missedSeconds}s perdidos, '
      '${compensatedSeconds}s compensados (UV: ${_currentUVIndex.toStringAsFixed(1)})',
      tag: 'ExposureProvider',
    );
    
    // Notificação de gap
    try {
      await NotificationService.showGapWarning(
        gapSeconds: missedSeconds,
        compensatedSeconds: compensatedSeconds,
        uvIndex: _currentUVIndex,
      );
    } catch (e) {
      AppLogger.warning('Erro ao exibir notificação de gap', tag: 'ExposureProvider', error: e);
    }
  }

  Future<void> _fetchUVData() async {
    // Modo Demo: UV simulado
    if (_isDemoMode) {
      _connectionStatus = ConnectionStatus.connected;
      _connectionError = null;
      _disconnectedSince = null;
      _currentUVIndex = _generateSimulatedUV();
      return;
    }
    
    // Evita chamadas HTTP concorrentes
    if (_isFetching) return;
    _isFetching = true;
    
    try {      
      final data = await UVDataService.fetchUVData();
      
      _currentUVIndex = data.uvIndex > 0 ? data.uvIndex : AppConstants.defaultUVIndex;
      
      if (data.isFromCache) {
        _disconnectedSince ??= DateTime.now();
        
        // Mostra cache após threshold
        if (shouldShowCacheIndicator) {
          _connectionStatus = ConnectionStatus.usingCache;
          // Notifica uso de cache (uma vez)
          if (!_cacheNotificationSent) {
            _cacheNotificationSent = true;
            try {
              await NotificationService.showCacheWarning();
            } catch (e) {
              AppLogger.warning('Erro ao exibir notificação de cache', tag: 'ExposureProvider', error: e);
            }
          }
        }
        
        // Verifica expiração do cache
        if (secondsDisconnected >= AppConstants.cacheExpiration.inSeconds) {
          await _stopDueToDisconnection();
          return;
        }
      } else {
        _connectionStatus = ConnectionStatus.connected;
        _disconnectedSince = null;
      }
      _connectionError = null;
      
      await StorageService.cacheUVData(_currentUVIndex);
      
    } on UVDataException catch (e) {
      _disconnectedSince ??= DateTime.now();
      
      // Mostra desconectado após threshold
      if (shouldShowCacheIndicator) {
        _connectionStatus = ConnectionStatus.disconnected;
        _connectionError = e.message;
      }
      
      // Verifica expiração do cache
      if (secondsDisconnected >= AppConstants.cacheExpiration.inSeconds) {
        await _stopDueToDisconnection();
        return;
      }
      
      // Fallback: cache local
      final cached = await StorageService.getCachedUVData();
      if (cached != null) {
        _currentUVIndex = cached['uvIndex'] as double;
        if (shouldShowCacheIndicator) {
          _connectionStatus = ConnectionStatus.usingCache;
          // Notifica o usuário sobre uso de cache (apenas uma vez)
          if (!_cacheNotificationSent) {
            _cacheNotificationSent = true;
            try {
              await NotificationService.showCacheWarning();
            } catch (e) {
              AppLogger.warning('Erro ao exibir notificação de cache', tag: 'ExposureProvider', error: e);
            }
          }
        }
      }
    } catch (e) {
      _disconnectedSince ??= DateTime.now();
      
      if (shouldShowCacheIndicator) {
        _connectionStatus = ConnectionStatus.disconnected;
        _connectionError = '${AppStrings.unexpectedError}: $e';
      }
      
      if (secondsDisconnected >= AppConstants.cacheExpiration.inSeconds) {
        await _stopDueToDisconnection();
        return;
      }
    } finally {
      _isFetching = false;
    }
  }
  
  /// Para o monitoramento por perda prolongada de conexão
  Future<void> _stopDueToDisconnection() async {
    _stoppedDueToDisconnection = true;
    _connectionError = AppStrings.monitoringStoppedNoConnection.replaceAll(
        '{minutes}', '${AppConstants.cacheExpiration.inMinutes}');
    
    // Notifica parada por desconexão
    try {
      await NotificationService.showMonitoringStopped();
    } catch (e) {
      AppLogger.warning('Erro ao exibir notificação de parada', tag: 'ExposureProvider', error: e);
    }
    
    await stopMonitoring();
  }

  /// Gera índice UV simulado (senoidal, 1–11) para modo Demo
  double _generateSimulatedUV() {
    final t = _secondsElapsed * 2 * pi / AppConstants.demoUVCyclePeriod;
    return AppConstants.demoUVCenter + AppConstants.demoUVAmplitude * sin(t);
  }

  /// Verifica conexão com o dispositivo IoT
  Future<void> _checkConnection() async {
    // Modo Demo: conexão sempre ok
    if (_isDemoMode) {
      _connectionStatus = ConnectionStatus.connected;
      notifyListeners();
      return;
    }
    
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();
    
    final isReachable = await UVDataService.isDeviceReachable();
    _connectionStatus = isReachable 
        ? ConnectionStatus.connected 
        : ConnectionStatus.disconnected;
    
    if (!isReachable) {
      _connectionError = AppStrings.deviceNotFound;
    }
    
    notifyListeners();
  }

  /// Tenta reconectar ao dispositivo IoT. Retorna true se bem-sucedido.
  Future<bool> retryConnection() async {
    UVDataService.resetUrlPreference();
    await _checkConnection();
    
    if (_connectionStatus == ConnectionStatus.connected) {
      _cacheNotificationSent = false;
      await NotificationService.cancel(AppConstants.notificationCacheId);
    }
    
    return _connectionStatus == ConnectionStatus.connected;
  }

  Future<void> _checkExposureLimits() async {
    // Aviso ao atingir 75%
    if (_model.isWarning && !_warningNotificationSent) {
      _warningNotificationSent = true;
      try {
        await NotificationService.showExposureWarning(_model.accumulatedExposurePercent);
      } catch (e) {
        AppLogger.warning('Erro ao exibir notificação de aviso', tag: 'ExposureProvider', error: e);
      }
    }
    
    // Alarme crítico ao atingir 100%
    if (_model.isCritical && !_alarmPlayed) {
      _alarmPlayed = true;
      final soundEnabled = await StorageService.isSoundAlarmEnabled();
      if (soundEnabled) {
        await _playAlarm();
      }
      try {
        await NotificationService.showExposureCritical();
      } catch (e) {
        AppLogger.warning('Erro ao exibir notificação crítica', tag: 'ExposureProvider', error: e);
      }
    }
  }

  Future<void> _playAlarm() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(AppConstants.alarmAssetPath));
      _alarmActive = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Erro ao reproduzir alarme', tag: 'ExposureProvider', error: e);
    }
  }

  /// Para o alarme sonoro
  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.release);
    _alarmActive = false;
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    await StorageService.saveLastSession(
      spf: _spf,
      skinType: _skinType,
      accumulatedExposure: _model.accumulatedExposurePercent,
      secondsElapsed: _secondsElapsed,
    );
  }

  Future<void> _saveSession() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;
    
    final session = ExposureSession(
      id: _currentSessionId!,
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
      spf: _spf,
      skinType: _skinType,
      maxExposurePercent: _model.accumulatedExposurePercent,
      maxUVIndex: _maxUVIndex,
      readings: _sessionReadings,
    );
    
    await StorageService.saveExposureSession(session);
    await StorageService.clearLastSession();
  }

  /// Restaura uma sessão anterior e retoma o monitoramento
  Future<bool> restoreLastSession() async {
    final lastSession = await StorageService.getLastSession();
    if (lastSession == null) return false;
    
    try {
      _spf = lastSession['spf'] as double;
      _skinType = lastSession['skinType'] as String;
      _model = ExposureModel(spf: _spf, skinType: _skinType);
      _model.setAccumulatedExposure(lastSession['accumulatedExposure'] as double);
      _secondsElapsed = lastSession['secondsElapsed'] as int;
      
      // Retoma monitoramento
      _isMonitoring = true;
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _sessionStartTime = DateTime.now().subtract(Duration(seconds: _secondsElapsed));
      
      await _checkConnection();
      await ForegroundService.start();
      
      _lastTickTime = DateTime.now();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _tick(),
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Erro ao restaurar sessão', tag: 'ExposureProvider', error: e);
      return false;
    }
  }

  /// Formata tempo em segundos para o formato HH:MM:SS
  String formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    ForegroundService.stop();
    super.dispose();
  }
}
