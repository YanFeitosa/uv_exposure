import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/exposure_model.dart';

/// Serviço responsável por exportar sessões de exposição em CSV ou JSON.
class ExportService {
  ExportService._();

  /// Exporta uma lista de sessões para CSV e retorna o caminho do arquivo.
  static Future<String> exportToCSV(List<ExposureSession> sessions) async {
    final buffer = StringBuffer();

    // Cabeçalho
    buffer.writeln(
      'ID,Início,Fim,Duração (min),Fototipo,FPS,Exposição Máx (%),UV Máx',
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
        '${s.maxExposurePercent.toStringAsFixed(1)},${s.maxUVIndex.toStringAsFixed(1)}',
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

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
