import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:uv_exposure_app/core/models/exposure_model.dart';
import 'package:uv_exposure_app/core/services/export_service.dart';

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
    tempDir = Directory.systemTemp.createTempSync('export_test_');
    PathProviderPlatform.instance = FakePathProvider(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  List<ExposureSession> _sampleSessions() {
    return [
      ExposureSession(
        id: '1',
        startTime: DateTime(2026, 4, 10, 10, 0),
        endTime: DateTime(2026, 4, 10, 11, 0),
        spf: 30,
        skinType: 'Tipo II - Clara',
        maxExposurePercent: 45.5,
        maxUVIndex: 7.2,
        readings: [
          UVReading(uvIndex: 5.0, timestamp: DateTime(2026, 4, 10, 10, 5)),
          UVReading(uvIndex: 7.2, timestamp: DateTime(2026, 4, 10, 10, 30)),
        ],
      ),
      ExposureSession(
        id: '2',
        startTime: DateTime(2026, 4, 11, 14, 0),
        endTime: DateTime(2026, 4, 11, 14, 30),
        spf: 50,
        skinType: 'Tipo IV - Morena',
        maxExposurePercent: 20.3,
        maxUVIndex: 4.1,
        readings: [],
      ),
    ];
  }

  group('ExportService — exportToCSV', () {
    test('deve gerar arquivo CSV com cabeçalho e dados', () async {
      final path = await ExportService.exportToCSV(_sampleSessions());
      final file = File(path);

      expect(file.existsSync(), isTrue);
      expect(path, contains('.csv'));

      final content = file.readAsStringSync();
      final lines = content.trim().split('\n');

      // Cabeçalho + 2 sessões
      expect(lines.length, equals(3));
      expect(lines[0], contains('ID'));
      expect(lines[0], contains('FPS'));
      expect(lines[0], contains('Exposição'));

      // Dados da primeira sessão
      expect(lines[1], contains('1'));
      expect(lines[1], contains('30'));
      expect(lines[1], contains('45.5'));
      expect(lines[1], contains('7.2'));

      // Dados da segunda sessão
      expect(lines[2], contains('2'));
      expect(lines[2], contains('50'));
    });

    test('deve escapar skinType com vírgula', () async {
      final sessions = [
        ExposureSession(
          id: '3',
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 1, 1, 0),
          spf: 15,
          skinType: 'Tipo I, Muito Clara',
          maxExposurePercent: 10.0,
          maxUVIndex: 3.0,
          readings: [],
        ),
      ];

      final path = await ExportService.exportToCSV(sessions);
      final content = File(path).readAsStringSync();

      // skinType com vírgula deve ser envolvido em aspas
      expect(content, contains('"Tipo I, Muito Clara"'));
    });
  });

  group('ExportService — exportToJSON', () {
    test('deve gerar arquivo JSON válido com metadados', () async {
      final path = await ExportService.exportToJSON(_sampleSessions());
      final file = File(path);

      expect(file.existsSync(), isTrue);
      expect(path, contains('.json'));

      final content = file.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['appName'], equals('SunSense'));
      expect(data['totalSessions'], equals(2));
      expect(data['exportDate'], isNotEmpty);
      expect(data['sessions'], isList);
      expect((data['sessions'] as List).length, equals(2));
    });

    test('deve conter dados de sessão corretos no JSON', () async {
      final path = await ExportService.exportToJSON(_sampleSessions());
      final content = File(path).readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final sessions = data['sessions'] as List;
      final first = sessions[0] as Map<String, dynamic>;

      expect(first['id'], equals('1'));
      expect(first['spf'], equals(30.0));
      expect(first['maxUVIndex'], equals(7.2));
    });
  });
}
