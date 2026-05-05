import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Cores principais do tema
  static const Color primary = Color(0xFFFFCE26);
  static const Color secondary = Color(0xFF77347A);

  // Cores de status de conexão
  static const Color connected = Colors.green;
  static const Color connecting = Colors.blue;
  static const Color usingCache = Colors.orange;
  static const Color disconnected = Colors.red;
  static const Color error = Color(0xFFE53935);

  // Cores da escala UV (OMS)
  static const Color uvLow = Colors.green; // 0-2
  static const Color uvModerate = Color(0xFFE6B800); // 3-5
  static const Color uvHigh = Colors.orange; // 6-7
  static const Color uvVeryHigh = Colors.red; // 8-10
  static const Color uvExtreme = Colors.purple; // 11+

  // Cores de nível de exposição
  static const Color exposureSafe = Colors.green;
  static const Color exposureWarning = Color(0xFFE6B800);
  static const Color exposureDanger = Colors.red;

  // Cor de notificação
  static const Color notificationCritical = Color(0xFFFF0000);

  // Cores de aviso (laranja)
  static const Color warning = Colors.orange;
  static const Color warningBackground = Color(0xFFFFE0B2); // orange.shade100
  static const Color warningBackgroundSubtle =
      Color(0xFFFFF3E0); // orange.shade50
  static const Color warningText = Color(0xFFF57C00); // orange.shade700
  static const Color warningTextStrong = Color(0xFFEF6C00); // orange.shade800
  static const Color warningTextDark = Color(0xFFE65100); // orange.shade900

  // Cores de erro (vermelho com variações)
  static const Color errorBackground = Color(0xFFFFCDD2); // red.shade100
  static const Color errorDark = Color(0xFFC62828); // red.shade800
  static const Color errorMuted = Color(0xFFE57373); // red.shade300

  // Cor informacional
  static const Color info = Colors.blue;

  // Cores de texto
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textOnPrimary = Colors.black;
  static const Color textOnSecondary = Colors.white;
  static const Color textOnCard =
      Colors.white; // texto sobre fundo roxo (cardBackground)
  static const Color textOnCardMuted = Color(0xB3FFFFFF); // white70
  static const Color textOnCardSubtle = Color(0x99FFFFFF); // white60
  static const Color textHint = Color(0xFF9E9E9E); // Colors.grey
  static const Color textSubtle = Color(0xFF616161); // grey.shade700

  // Cores de estado vazio
  static const Color emptyStateIcon = Color(0xFFBDBDBD); // grey.shade400
  static const Color emptyStateText = Color(0xFF757575); // grey.shade600

  // Sombra
  static const Color shadow = Color(0x1A000000); // black com 10% de opacidade

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

  /// Retorna a cor interpolada pela porcentagem de exposição.
  /// De 0% a 75%: transição verde → amarelo.
  /// De 75% a 100%: transição amarelo → vermelho.
  static Color getExposureColor(double exposurePercent) {
    if (exposurePercent <= 75) {
      return Color.lerp(exposureSafe, exposureWarning, exposurePercent / 75)!;
    }
    return Color.lerp(
        exposureWarning, exposureDanger, (exposurePercent - 75) / 25)!;
  }
}
