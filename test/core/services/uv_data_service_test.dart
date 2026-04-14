import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

// ─────────────────────────────────────────────
// Mock do http.Client
// ─────────────────────────────────────────────
class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    UVDataService.setHttpClient(mockClient);
    UVDataService.clearCache();
    UVDataService.resetUrlPreference();
  });

  tearDown(() {
    UVDataService.restoreHttpClient();
  });

  // Helper para criar response HTTP
  http.Response jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
    return http.Response(jsonEncode(body), statusCode);
  }

  // ─────────────────────────────────────────────
  // UVData — Parsing de JSON
  // ─────────────────────────────────────────────
  group('UVData.fromJson', () {
    test('deve parsear chave "uv_index"', () {
      final data = UVData.fromJson({'uv_index': 7.5});
      expect(data.uvIndex, equals(7.5));
    });

    test('deve parsear chave "uvIndex"', () {
      final data = UVData.fromJson({'uvIndex': 3.2});
      expect(data.uvIndex, equals(3.2));
    });

    test('deve parsear chave "indiceUV"', () {
      final data = UVData.fromJson({'indiceUV': 9.0});
      expect(data.uvIndex, equals(9.0));
    });

    test('deve lançar UVDataException quando nenhuma chave UV está presente', () {
      expect(
        () => UVData.fromJson({'temperatura': 30}),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve lançar UVDataException para valor não numérico', () {
      expect(
        () => UVData.fromJson({'uv_index': 'invalid'}),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve converter inteiro para double', () {
      final data = UVData.fromJson({'uv_index': 5});
      expect(data.uvIndex, equals(5.0));
      expect(data.uvIndex, isA<double>());
    });

    test('deve priorizar uv_index sobre uvIndex', () {
      final data = UVData.fromJson({'uv_index': 3.0, 'uvIndex': 7.0});
      expect(data.uvIndex, equals(3.0));
    });

    test('timestamp deve ser preenchido automaticamente', () {
      final before = DateTime.now();
      final data = UVData.fromJson({'uv_index': 5.0});
      final after = DateTime.now();
      expect(data.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(data.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('isFromCache deve ser false por padrão', () {
      final data = UVData.fromJson({'uv_index': 5.0});
      expect(data.isFromCache, isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // UVData — copyWithCache
  // ─────────────────────────────────────────────
  group('UVData.copyWithCache', () {
    test('deve marcar isFromCache como true', () {
      final data = UVData.fromJson({'uv_index': 5.0});
      final cached = data.copyWithCache();
      expect(cached.isFromCache, isTrue);
      expect(cached.uvIndex, equals(data.uvIndex));
    });
  });

  // ─────────────────────────────────────────────
  // UVData — Serialização
  // ─────────────────────────────────────────────
  group('UVData.toJson', () {
    test('deve serializar corretamente', () {
      final data = UVData(
        uvIndex: 8.0,
        timestamp: DateTime(2026, 6, 1, 12, 0, 0),
      );
      final json = data.toJson();
      expect(json['uvIndex'], equals(8.0));
      expect(json['timestamp'], isA<String>());
    });
  });

  // ─────────────────────────────────────────────
  // UVDataException
  // ─────────────────────────────────────────────
  group('UVDataException', () {
    test('toString sem statusCode', () {
      const ex = UVDataException('Erro de rede');
      expect(ex.toString(), equals('UVDataException: Erro de rede'));
    });

    test('toString com statusCode', () {
      const ex = UVDataException('Falha', statusCode: 500);
      expect(ex.toString(), equals('UVDataException: Falha (Status: 500)'));
    });

    test('deve armazenar originalError', () {
      final original = Exception('original');
      final ex = UVDataException('Erro', originalError: original);
      expect(ex.originalError, equals(original));
    });
  });

  // ─────────────────────────────────────────────
  // fetchUVData — Sucesso
  // ─────────────────────────────────────────────
  group('fetchUVData - sucesso', () {
    test('deve retornar dados ao buscar via mDNS (URL primária)', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 7.0}));

      final data = await UVDataService.fetchUVData();
      expect(data.uvIndex, equals(7.0));
      expect(data.isFromCache, isFalse);
    });

    test('deve fazer fallback para IP quando mDNS falha', () async {
      var callCount = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        callCount++;
        final url = invocation.positionalArguments[0] as Uri;
        if (url.host == 'sunsense.local') {
          throw http.ClientException('DNS lookup failed');
        }
        return jsonResponse({'uv_index': 5.0});
      });

      final data = await UVDataService.fetchUVData();
      expect(data.uvIndex, equals(5.0));
      expect(callCount, equals(2));
    });

    test('deve memorizar URL que funcionou (fallback IP)', () async {
      // Primeira chamada: mDNS falha, IP funciona
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        if (url.host == 'sunsense.local') {
          throw http.ClientException('DNS failed');
        }
        return jsonResponse({'uv_index': 4.0});
      });

      await UVDataService.fetchUVData();

      // Reset mock para segunda chamada - verificar que tenta IP primeiro
      reset(mockClient);
      final urlsUsed = <String>[];
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        urlsUsed.add(url.host);
        return jsonResponse({'uv_index': 6.0});
      });

      await UVDataService.fetchUVData();
      // Primeiro URL tentado deve ser o IP (memorizado)
      expect(urlsUsed.first, equals(AppConstants.deviceFallbackIp));
    });

    test('deve cachear dados em memória após sucesso', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 9.0}));

      await UVDataService.fetchUVData();
      final cached = UVDataService.getCachedData();
      expect(cached, isNotNull);
      expect(cached!.uvIndex, equals(9.0));
    });
  });

  // ─────────────────────────────────────────────
  // fetchUVData — Fallback para cache
  // ─────────────────────────────────────────────
  group('fetchUVData - fallback para cache', () {
    test('deve retornar cache quando ambas URLs falham', () async {
      // Primeiro, popular o cache
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 6.0}));
      await UVDataService.fetchUVData();

      // Agora, ambas falham
      reset(mockClient);
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(http.ClientException('Network error'));

      final data = await UVDataService.fetchUVData();
      expect(data.uvIndex, equals(6.0));
      expect(data.isFromCache, isTrue);
    });

    test('deve lançar UVDataException quando tudo falha e sem cache', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(http.ClientException('Network error'));

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // fetchUVData — Erros HTTP
  // ─────────────────────────────────────────────
  group('fetchUVData - erros HTTP', () {
    test('deve tratar status 500 como falha', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve tratar status 404 como falha', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve tratar timeout como falha', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        throw TimeoutException('Connection timed out');
      });

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // getCachedData
  // ─────────────────────────────────────────────
  group('getCachedData', () {
    test('deve retornar null quando cache está vazio', () {
      expect(UVDataService.getCachedData(), isNull);
    });

    test('deve retornar dados quando cache é válido', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 4.0}));

      await UVDataService.fetchUVData();
      final cached = UVDataService.getCachedData();
      expect(cached, isNotNull);
      expect(cached!.uvIndex, equals(4.0));
    });

    test('deve retornar null após clearCache', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 4.0}));

      await UVDataService.fetchUVData();
      UVDataService.clearCache();
      expect(UVDataService.getCachedData(), isNull);
    });
  });

  // ─────────────────────────────────────────────
  // isDeviceReachable
  // ─────────────────────────────────────────────
  group('isDeviceReachable', () {
    test('deve retornar true quando dispositivo responde 200', () async {
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response('OK', 200));

      final reachable = await UVDataService.isDeviceReachable();
      expect(reachable, isTrue);
    });

    test('deve retornar false quando dispositivo responde 500', () async {
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response('Error', 500));

      final reachable = await UVDataService.isDeviceReachable();
      expect(reachable, isFalse);
    });

    test('deve retornar false em timeout', () async {
      when(() => mockClient.get(any()))
          .thenAnswer((_) async {
        throw TimeoutException('timeout');
      });

      final reachable = await UVDataService.isDeviceReachable();
      expect(reachable, isFalse);
    });

    test('deve retornar false em erro de rede', () async {
      when(() => mockClient.get(any()))
          .thenThrow(http.ClientException('No route'));

      final reachable = await UVDataService.isDeviceReachable();
      expect(reachable, isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // resetUrlPreference
  // ─────────────────────────────────────────────
  group('resetUrlPreference', () {
    test('deve voltar a tentar mDNS primeiro após reset', () async {
      // Forçar uso de fallback IP
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        if (url.host == 'sunsense.local') {
          throw http.ClientException('DNS failed');
        }
        return jsonResponse({'uv_index': 3.0});
      });
      await UVDataService.fetchUVData();

      // Reset preferência
      UVDataService.resetUrlPreference();

      // Verificar que mDNS é tentado primeiro
      reset(mockClient);
      final urlsUsed = <String>[];
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        urlsUsed.add(url.host);
        return jsonResponse({'uv_index': 5.0});
      });

      await UVDataService.fetchUVData();
      expect(urlsUsed.first, equals('sunsense.local'));
    });
  });
}
