import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/exposure_model.dart';

/// Serviço responsável por exportar sessões de exposição em CSV ou JSON.
class ExportService {
  ExportService._();

  /// Exporta uma lista de sessões para CSV e retorna o caminho do arquivo.
  static Future<String> exportToCSV(List<ExposureSession> sessions) async {
    final buffer = StringBuffer();

    // Cabeçalho
    buffer.writeln(
      'ID,Início,Fim,Duração (min),Fototipo,FPS,Exposição Máx (%),UV Máx,Leituras',
    );

    for (final s in sessions) {
      final start = _formatDateTime(s.startTime);
      final end = s.endTime != null ? _formatDateTime(s.endTime!) : '';
      final durationMin = s.duration.inMinutes;
      // Escapa aspas no skinType se necessário
      final skinType =
          s.skinType.contains(',') ? '"${s.skinType}"' : s.skinType;

      buffer.writeln(
        '${s.id},$start,$end,$durationMin,$skinType,${s.spf.toInt()},'
        '${s.maxExposurePercent.toStringAsFixed(1)},${s.maxUVIndex.toStringAsFixed(1)},'
        '${s.readings.length}',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/sunsense_export_$timestamp.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Exporta uma lista de sessões para JSON e retorna o caminho do arquivo.
  static Future<String> exportToJSON(List<ExposureSession> sessions) async {
    final data = sessions.map((s) => s.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert({
      'appName': 'SunSense',
      'exportDate': DateTime.now().toIso8601String(),
      'totalSessions': sessions.length,
      'sessions': data,
    });

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/sunsense_export_$timestamp.json');
    await file.writeAsString(jsonStr);
    return file.path;
  }

  /// Abre a bottom sheet nativa do sistema para compartilhar o arquivo.
  ///
  /// Em plataformas sem suporte a share (testes, desktop sem integração),
  /// a chamada falha silenciosamente e o caller pode usar o [path] como
  /// fallback para mostrar ao usuário.
  static Future<ShareResult> shareFile(
    String path, {
    String? subject,
    String? text,
  }) async {
    try {
      return await Share.shareXFiles(
        [XFile(path)],
        subject: subject,
        text: text,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ExportService.shareFile falhou: $e');
      }
      return ShareResult(
        'Compartilhamento indisponível',
        ShareResultStatus.unavailable,
      );
    }
  }

  /// Exporta o histórico no formato indicado ('csv' ou 'json') e em seguida
  /// abre a bottom sheet de compartilhamento.
  ///
  /// Retorna o caminho do arquivo gerado (mesmo quando o compartilhamento
  /// for cancelado ou indisponível), para que o caller possa exibir um
  /// fallback informando o local salvo.
  static Future<ExportAndShareResult> exportAndShare(
    List<ExposureSession> sessions, {
    required String format,
    String? subject,
    String? text,
  }) async {
    final path = format.toLowerCase() == 'json'
        ? await exportToJSON(sessions)
        : await exportToCSV(sessions);

    final share = await shareFile(path, subject: subject, text: text);
    return ExportAndShareResult(path: path, shareResult: share);
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Resultado combinado de exportação + compartilhamento.
class ExportAndShareResult {
  final String path;
  final ShareResult shareResult;

  const ExportAndShareResult({
    required this.path,
    required this.shareResult,
  });

  bool get wasShared => shareResult.status == ShareResultStatus.success;
  bool get wasDismissed => shareResult.status == ShareResultStatus.dismissed;
  bool get isUnavailable =>
      shareResult.status == ShareResultStatus.unavailable;
}
