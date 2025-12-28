import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';
import '../models/exposure_model.dart';
import '../services/uv_data_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Estados de conexão do dispositivo
enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  usingCache,
}

/// Provider para gerenciar o estado do monitoramento de exposição UV
class ExposureProvider extends ChangeNotifier {
  // Configurações
  late double _spf;
  late String _skinType;
  
  // Modelo
  late ExposureModel _model;
  
  // Estado de monitoramento
  bool _isMonitoring = false;
  int _secondsElapsed = 0;
  double _currentUVIndex = 1.0;
  Timer? _timer;
  
  // Estado de conexão
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _connectionError;
  DateTime? _disconnectedSince; // Quando perdeu conexão
  bool _stoppedDueToDisconnection = false; // Se parou por falta de conexão
  
  // Alarme
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _alarmPlayed = false;
  bool _warningNotificationSent = false;
  
  // Sessão atual
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  List<UVReading> _sessionReadings = [];
  double _maxUVIndex = 0.0;

  // Getters
  bool get isMonitoring => _isMonitoring;
  int get secondsElapsed => _secondsElapsed;
  double get currentUVIndex => _currentUVIndex;
  double get spf => _spf;
  String get skinType => _skinType;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get connectionError => _connectionError;
  bool get alarmPlayed => _alarmPlayed;
  bool get stoppedDueToDisconnection => _stoppedDueToDisconnection;
  
  /// Retorna se deve mostrar o indicador de uso de cache (após 3s de desconexão)
  bool get shouldShowCacheIndicator {
    if (_disconnectedSince == null) return false;
    return secondsDisconnected >= AppConstants.cacheIndicatorThreshold.inSeconds;
  }
  
  /// Retorna há quanto tempo está desconectado (em segundos)
  int get secondsDisconnected {
    if (_disconnectedSince == null) return 0;
    return DateTime.now().difference(_disconnectedSince!).inSeconds;
  }
  
  /// Retorna o tempo restante de cache antes de parar (em segundos)
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
    _currentUVIndex = 1.0;
    _alarmPlayed = false;
    _warningNotificationSent = false;
    _connectionError = null;
    _disconnectedSince = null;
    _stoppedDueToDisconnection = false;
    _sessionReadings = [];
    _maxUVIndex = 0.0;
    _model.reset();
  }

  /// Inicia o monitoramento de exposição
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _resetState();
    _isMonitoring = true;
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
    
    // Verifica conexão inicial
    await _checkConnection();
    
    // Inicia o timer
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
    
    notifyListeners();
  }

  /// Para o monitoramento e salva a sessão
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;

    // Salva a sessão no histórico
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
    // Incrementa tempo
    _secondsElapsed++;
    
    // Acumula exposição (baseado em 1 segundo)
    _model.accumulateExposure(_currentUVIndex, 1);
    
    // Busca dados UV periodicamente (conforme intervalo configurado)
    if (_secondsElapsed % AppConstants.dataFetchInterval.inSeconds == 0) {
      await _fetchUVData();
      
      // Registra leitura e atualiza máximo apenas quando busca novos dados
      _sessionReadings.add(UVReading(
        uvIndex: _currentUVIndex,
        timestamp: DateTime.now(),
      ));
      
      if (_currentUVIndex > _maxUVIndex) {
        _maxUVIndex = _currentUVIndex;
      }
    }
    
    // Verifica limites
    await _checkExposureLimits();
    
    // Salva progresso periodicamente
    if (_secondsElapsed % 30 == 0) {
      await _saveProgress();
    }
    
    notifyListeners();
  }

  Future<void> _fetchUVData() async {
    try {
      _connectionStatus = ConnectionStatus.connecting;
      
      final data = await UVDataService.fetchUVData();
      
      _currentUVIndex = data.uvIndex > 0 ? data.uvIndex : 1.0;
      
      if (data.isFromCache) {
        // Marca quando começou a usar cache (se ainda não marcou)
        _disconnectedSince ??= DateTime.now();
        
        // Só mostra status de cache após o threshold (3s)
        if (shouldShowCacheIndicator) {
          _connectionStatus = ConnectionStatus.usingCache;
        } else {
          _connectionStatus = ConnectionStatus.connected; // Mantém como conectado durante o threshold
        }
        
        // Verifica se o tempo de cache expirou
        if (secondsDisconnected >= AppConstants.cacheExpiration.inSeconds) {
          await _stopDueToDisconnection();
          return;
        }
      } else {
        _connectionStatus = ConnectionStatus.connected;
        _disconnectedSince = null; // Reconectou, reseta o contador
      }
      _connectionError = null;
      
      await StorageService.cacheUVData(_currentUVIndex);
      
    } on UVDataException catch (e) {
      // Marca quando começou a desconexão
      _disconnectedSince ??= DateTime.now();
      
      // Só mostra status de desconectado/cache após o threshold (3s)
      if (shouldShowCacheIndicator) {
        _connectionStatus = ConnectionStatus.disconnected;
        _connectionError = e.message;
      } else {
        _connectionStatus = ConnectionStatus.connected; // Mantém como conectado durante o threshold
      }
      
      // Verifica se já passou o tempo máximo sem conexão
      if (secondsDisconnected >= AppConstants.cacheExpiration.inSeconds) {
        await _stopDueToDisconnection();
        return;
      }
      
      // Tenta usar cache local
      final cached = await StorageService.getCachedUVData();
      if (cached != null) {
        _currentUVIndex = cached['uvIndex'] as double;
        if (shouldShowCacheIndicator) {
          _connectionStatus = ConnectionStatus.usingCache;
        }
      }
    } catch (e) {
      _disconnectedSince ??= DateTime.now();
      
      if (shouldShowCacheIndicator) {
        _connectionStatus = ConnectionStatus.disconnected;
        _connectionError = 'Unexpected error: $e';
      }
      
      if (secondsDisconnected >= AppConstants.cacheExpiration.inSeconds) {
        await _stopDueToDisconnection();
        return;
      }
    }
  }
  
  /// Para o monitoramento devido à perda de conexão prolongada
  Future<void> _stopDueToDisconnection() async {
    _stoppedDueToDisconnection = true;
    _connectionError = 'Monitoring stopped: No connection for ${AppConstants.cacheExpiration.inMinutes} minutes';
    await stopMonitoring();
  }

  Future<void> _checkConnection() async {
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();
    
    final isReachable = await UVDataService.isDeviceReachable();
    _connectionStatus = isReachable 
        ? ConnectionStatus.connected 
        : ConnectionStatus.disconnected;
    
    if (!isReachable) {
      _connectionError = 'Device not found. Make sure you\'re connected to the same WiFi network.';
    }
    
    notifyListeners();
  }

  /// Tenta reconectar ao dispositivo
  Future<void> retryConnection() async {
    UVDataService.resetUrlPreference();
    await _checkConnection();
  }

  Future<void> _checkExposureLimits() async {
    // Notificação de aviso (75%)
    if (_model.isWarning && !_warningNotificationSent) {
      _warningNotificationSent = true;
      try {
        await NotificationService.showExposureWarning(_model.accumulatedExposurePercent);
      } catch (e) {
        debugPrint('Error showing warning notification: $e');
      }
    }
    
    // Alarme crítico (100%)
    if (_model.isCritical && !_alarmPlayed) {
      _alarmPlayed = true;
      await _playAlarm();
      try {
        await NotificationService.showExposureCritical();
      } catch (e) {
        debugPrint('Error showing critical notification: $e');
      }
    }
  }

  Future<void> _playAlarm() async {
    try {
      await _audioPlayer.play(AssetSource('audio/alarm.mp3'));
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  /// Para o alarme
  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
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

  /// Restaura uma sessão anterior
  Future<bool> restoreLastSession() async {
    final lastSession = await StorageService.getLastSession();
    if (lastSession == null) return false;
    
    try {
      _spf = lastSession['spf'] as double;
      _skinType = lastSession['skinType'] as String;
      _model = ExposureModel(spf: _spf, skinType: _skinType);
      _model.setAccumulatedExposure(lastSession['accumulatedExposure'] as double);
      _secondsElapsed = lastSession['secondsElapsed'] as int;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      return false;
    }
  }

  /// Formata segundos para HH:MM:SS
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
    super.dispose();
  }
}
