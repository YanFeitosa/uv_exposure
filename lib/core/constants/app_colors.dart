import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Cores principais do tema
  static const Color primary = Color(0xFFFFCE26);
  static const Color secondary = Color(0xFF77347A);

  // Cores de status de conexão
  static const Color connected = Colors.green;
  static const Color disconnected = Colors.red;
  static const Color error = Color(0xFFE53935);

  // Cores da escala UV (OMS)
  static const Color uvLow = Colors.green;           // 0-2
  static const Color uvModerate = Colors.yellow;     // 3-5
  static const Color uvHigh = Colors.orange;         // 6-7
  static const Color uvVeryHigh = Colors.red;        // 8-10
  static const Color uvExtreme = Colors.purple;      // 11+

  // Cores de nível de exposição
  static const Color exposureSafe = Colors.green;
  static const Color exposureWarning = Colors.yellow;
  static const Color exposureDanger = Colors.red;

  // Cor de notificação
  static const Color notificationCritical = Color(0xFFFF0000);

  // Cores de texto
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textOnPrimary = Colors.black;
  static const Color textOnSecondary = Colors.white;

  // Cores de fundo
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFF77347A);

  /// Retorna a cor correspondente ao índice UV (escala OMS)
  static Color getUVIndexColor(double uvIndex) {
    if (uvIndex <= 2) return uvLow;
    if (uvIndex <= 5) return uvModerate;
    if (uvIndex <= 7) return uvHigh;
    if (uvIndex <= 10) return uvVeryHigh;
    return uvExtreme;
  }

  /// Retorna a cor interpolada pela porcentagem de exposição
  static Color getExposureColor(double exposurePercent) {
    if (exposurePercent <= 50) {
      return Color.lerp(exposureSafe, exposureWarning, exposurePercent / 50)!;
    }
    return Color.lerp(exposureWarning, exposureDanger, (exposurePercent - 50) / 50)!;
  }
}
