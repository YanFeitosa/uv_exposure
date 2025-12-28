import '../constants/app_constants.dart';

/// Modelo de dados para uma leitura UV
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

/// Modelo de dados para uma sessão de exposição
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

  factory ExposureSession.fromJson(Map<String, dynamic> json) => ExposureSession(
    id: json['id'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    spf: (json['spf'] as num).toDouble(),
    skinType: json['skinType'] as String,
    maxExposurePercent: (json['maxExposurePercent'] as num).toDouble(),
    maxUVIndex: (json['maxUVIndex'] as num).toDouble(),
    readings: (json['readings'] as List<dynamic>?)
        ?.map((r) => UVReading.fromJson(r as Map<String, dynamic>))
        .toList() ?? [],
  );
}

/// Modelo de cálculo de exposição UV com encapsulamento adequado
class ExposureModel {
  final double _tep;
  final double _spf;
  double _accumulatedExposurePercent = 0.0;

  /// Cria um novo modelo de exposição.
  /// 
  /// [spf] - Fator de proteção solar do protetor utilizado
  /// [skinType] - Tipo de pele (Fitzpatrick scale)
  ExposureModel({required double spf, required String skinType})
      : _spf = spf,
        _tep = _calculateTEP(skinType);

  /// Calcula o TEP baseado no tipo de pele
  static double _calculateTEP(String skinType) {
    return AppConstants.tepBySkinType[skinType] ?? 15.0;
  }

  /// Retorna o TEP (Tempo de Eritema Pele) em minutos
  double get tep => _tep;

  /// Retorna o SPF atual
  double get spf => _spf;

  /// Retorna a porcentagem de exposição acumulada
  double get accumulatedExposurePercent => _accumulatedExposurePercent;

  /// Converte horas, minutos e segundos para segundos totais
  int _toSeconds(int hours, int minutes, int seconds) {
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  /// Calcula o tempo inicial de exposição segura baseado no índice UV
  /// 
  /// Retorna o tempo em segundos
  int calculateInitialSafeExposureTime(double uvIndex) {
    if (uvIndex <= 0) uvIndex = 1;
    final safeTimeMinutes = (_spf * _tep) / uvIndex;
    return _toSeconds(0, safeTimeMinutes.toInt(), 0);
  }

  /// Acumula a exposição baseado no índice UV e tempo decorrido
  /// 
  /// [uvIndex] - Índice UV atual
  /// [timeSeconds] - Tempo de exposição em segundos
  void accumulateExposure(double uvIndex, int timeSeconds) {
    if (uvIndex <= 0) return;
    _accumulatedExposurePercent += (uvIndex * timeSeconds) / (_tep * _spf * 60);
  }

  /// Calcula o tempo de exposição segura restante
  /// 
  /// [secondsElapsed] - Segundos já decorridos
  /// Retorna o tempo total seguro em segundos
  int calculateSafeExposureTime(int secondsElapsed) {
    if (_accumulatedExposurePercent <= 0.0001) return 0;
    return ((secondsElapsed * 100) / _accumulatedExposurePercent).toInt();
  }

  /// Calcula o tempo restante de exposição segura
  int calculateRemainingSafeTime(int secondsElapsed) {
    final totalSafeTime = calculateSafeExposureTime(secondsElapsed);
    final remaining = totalSafeTime - secondsElapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica se a exposição atingiu o limite crítico
  bool get isCritical => _accumulatedExposurePercent >= AppConstants.exposureCriticalThreshold;

  /// Verifica se a exposição atingiu o limite de aviso
  bool get isWarning => _accumulatedExposurePercent >= AppConstants.exposureWarningThreshold;

  /// Reseta a exposição acumulada
  void reset() {
    _accumulatedExposurePercent = 0.0;
  }

  /// Define manualmente a exposição acumulada (para restaurar sessões)
  void setAccumulatedExposure(double value) {
    _accumulatedExposurePercent = value.clamp(0.0, double.infinity);
  }
}
