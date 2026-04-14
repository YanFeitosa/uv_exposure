import '../constants/app_constants.dart';

/// Modelo de dados para uma leitura individual de UV
class UVReading {
  final double uvIndex;
  final DateTime timestamp;

  const UVReading({
    required this.uvIndex,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'uvIndex': uvIndex,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UVReading.fromJson(Map<String, dynamic> json) => UVReading(
    uvIndex: (json['uvIndex'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Modelo de dados para uma sessão completa de exposição UV
class ExposureSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double spf;
  final String skinType;
  final double maxExposurePercent;
  final double maxUVIndex;
  final List<UVReading> readings;

  const ExposureSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.spf,
    required this.skinType,
    required this.maxExposurePercent,
    required this.maxUVIndex,
    this.readings = const [],
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  ExposureSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? spf,
    String? skinType,
    double? maxExposurePercent,
    double? maxUVIndex,
    List<UVReading>? readings,
  }) {
    return ExposureSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      spf: spf ?? this.spf,
      skinType: skinType ?? this.skinType,
      maxExposurePercent: maxExposurePercent ?? this.maxExposurePercent,
      maxUVIndex: maxUVIndex ?? this.maxUVIndex,
      readings: readings ?? this.readings,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'spf': spf,
    'skinType': skinType,
    'maxExposurePercent': maxExposurePercent,
    'maxUVIndex': maxUVIndex,
    'readings': readings.map((r) => r.toJson()).toList(),
  };

  factory ExposureSession.fromJson(Map<String, dynamic> json) {
    try {
      return ExposureSession(
        id: (json['id'] as String?) ?? 'unknown',
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : DateTime.now(),
        endTime: json['endTime'] != null
            ? DateTime.tryParse(json['endTime'] as String)
            : null,
        spf: (json['spf'] as num?)?.toDouble() ?? 0.0,
        skinType: (json['skinType'] as String?) ?? 'Tipo II - Clara',
        maxExposurePercent: (json['maxExposurePercent'] as num?)?.toDouble() ?? 0.0,
        maxUVIndex: (json['maxUVIndex'] as num?)?.toDouble() ?? 0.0,
        readings: (json['readings'] as List<dynamic>?)
            ?.map((r) {
              try {
                return UVReading.fromJson(r as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<UVReading>()
            .toList() ?? [],
      );
    } catch (e) {
      return ExposureSession(
        id: 'corrupted-${DateTime.now().millisecondsSinceEpoch}',
        startTime: DateTime.now(),
        spf: 0,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 0,
        maxUVIndex: 0,
      );
    }
  }
}

/// Modelo de cálculo de exposição UV.
/// Encapsula TEP, SPF e fórmulas de acúmulo e tempo seguro.
class ExposureModel {
  final double _tep;
  final double _spf;
  double _accumulatedExposurePercent = 0.0;

  /// Cria um novo modelo de exposição.
  ExposureModel({required double spf, required String skinType})
      : _spf = spf <= 0 ? 1.0 : spf,
        _tep = _calculateTEP(skinType);

  /// Calcula o TEP baseado no fototipo de pele
  static double _calculateTEP(String skinType) {
    return AppConstants.tepBySkinType[skinType] ?? AppConstants.defaultTEP;
  }

  /// Retorna o TEP em minutos
  double get tep => _tep;

  /// Retorna o SPF atual
  double get spf => _spf;

  /// Retorna a porcentagem de exposição acumulada
  double get accumulatedExposurePercent => _accumulatedExposurePercent;

  /// Calcula o tempo inicial de exposição segura baseado no índice UV atual
  /// 
  /// Retorna o tempo em segundos: (SPF × TEP) / UV
  int calculateInitialSafeExposureTime(double uvIndex) {
    if (uvIndex <= 0) uvIndex = 1;
    final safeTimeSeconds = ((_spf * _tep) / uvIndex) * 60;
    return safeTimeSeconds.toInt();
  }

  /// Acumula a exposição UV proporcionalmente ao índice UV e tempo decorrido
  /// 
  /// uvIndex - Índice UV atual do sensor
  /// timeSeconds - Intervalo de tempo em segundos (normalmente 1)
  void accumulateExposure(double uvIndex, int timeSeconds) {
    if (uvIndex <= 0) return;
    _accumulatedExposurePercent += ((uvIndex * timeSeconds) / (_tep * _spf * 60)) * 100;
  }

  /// Calcula o tempo total de exposição segura estimado
  /// Retorna estimativa do tempo total seguro em segundos
  int calculateSafeExposureTime(int secondsElapsed) {
    if (_accumulatedExposurePercent <= AppConstants.minExposureThreshold) return 0;
    return ((secondsElapsed * 100) / _accumulatedExposurePercent).toInt();
  }

  /// Calcula o tempo restante de exposição segura (total - decorrido)
  int calculateRemainingSafeTime(int secondsElapsed) {
    final totalSafeTime = calculateSafeExposureTime(secondsElapsed);
    final remaining = totalSafeTime - secondsElapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica se a exposição atingiu o limite crítico
  bool get isCritical => _accumulatedExposurePercent >= AppConstants.exposureCriticalThreshold;

  /// Verifica se a exposição atingiu o limite de aviso
  bool get isWarning => _accumulatedExposurePercent >= AppConstants.exposureWarningThreshold;

  /// Reseta a exposição acumulada para zero
  void reset() {
    _accumulatedExposurePercent = 0.0;
  }

  /// Define manualmente a exposição acumulada (usado para restaurar sessões salvas)
  void setAccumulatedExposure(double value) {
    _accumulatedExposurePercent = value.clamp(0.0, double.infinity);
  }
}
