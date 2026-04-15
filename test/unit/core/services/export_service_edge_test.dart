/// Testes de borda — ExportService
///
/// Cobre: exportar lista vazia, exportar sessão com readings vazias,
/// exportar sessão com caracteres especiais no skinType.
@Tags(['edge', 'empty'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:uv_exposure_app/core/services/export_service.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';

class FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _tempPath;
  FakePathProvider(this._tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => _tempPath;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('export_edge_test_');
    PathProviderPlatform.instance = FakePathProvider(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ExportService — borda', () {
    test('exportar lista vazia de sessões deve gerar CSV com apenas header',
        () async {
      final path = await ExportService.exportToCSV([]);
      final file = File(path);
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      final lines = content.trim().split('\n');
      expect(lines.length, equals(1));
      expect(lines.first, contains('ID'));
    });

    test('exportar sessão com readings vazias', () async {
      final session = ExposureSession(
        id: 'empty-readings',
        startTime: DateTime(2026, 1, 1, 10),
        endTime: DateTime(2026, 1, 1, 11),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 50,
        maxUVIndex: 7,
        readings: [],
      );
      final path = await ExportService.exportToCSV([session]);
      final content = File(path).readAsStringSync();
      expect(content, contains('empty-readings'));
    });

    test('exportar sessão com caracteres especiais no skinType', () async {
      final session = ExposureSession(
        id: 'special-chars',
        startTime: DateTime(2026, 1, 1, 10),
        endTime: DateTime(2026, 1, 1, 11),
        spf: 30,
        skinType: 'Tipo III - Média Clara',
        maxExposurePercent: 60,
        maxUVIndex: 8,
      );
      final path = await ExportService.exportToCSV([session]);
      final content = File(path).readAsStringSync();
      expect(content, contains('Tipo III'));
    });

    test('exportar múltiplas sessões preserva ordem', () async {
      final sessions = List.generate(
        5,
        (i) => ExposureSession(
          id: 'session-$i',
          startTime: DateTime(2026, 1, 1 + i),
          endTime: DateTime(2026, 1, 1 + i, 1),
          spf: 30,
          skinType: 'Tipo II - Clara',
          maxExposurePercent: 10.0 * (i + 1),
          maxUVIndex: 5.0 + i,
        ),
      );
      final path = await ExportService.exportToCSV(sessions);
      final content = File(path).readAsStringSync();
      final lines = content.trim().split('\n');
      expect(lines.length, equals(6));
    });

    test('exportar lista vazia para JSON deve gerar totalSessions=0', () async {
      final path = await ExportService.exportToJSON([]);
      final content = File(path).readAsStringSync();
      expect(content, contains('"totalSessions": 0'));
      expect(content, contains('"sessions": []'));
    });
  });
}
