// Testes unitários — UVDataService
//
// Cobre parsing JSON, serialização, busca HTTP com sucesso, cache e reachability.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';
import 'package:uv_exposure_app/core/constants/app_constants.dart';

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

  http.Response jsonResponse(Map<String, dynamic> body,
      {int statusCode = 200}) {
    return http.Response(jsonEncode(body), statusCode);
  }

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
      expect(
          data.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(data.timestamp.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
    });

    test('isFromCache deve ser false por padrão', () {
      final data = UVData.fromJson({'uv_index': 5.0});
      expect(data.isFromCache, isFalse);
    });
  });

  group('UVData.copyWithCache', () {
    test('deve marcar isFromCache como true', () {
      final data = UVData.fromJson({'uv_index': 5.0});
      final cached = data.copyWithCache();
      expect(cached.isFromCache, isTrue);
      expect(cached.uvIndex, equals(data.uvIndex));
    });
  });

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

  group('fetchUVData — sucesso', () {
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
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        if (url.host == 'sunsense.local') {
          throw http.ClientException('DNS failed');
        }
        return jsonResponse({'uv_index': 4.0});
      });
      await UVDataService.fetchUVData();

      reset(mockClient);
      final urlsUsed = <String>[];
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        urlsUsed.add(url.host);
        return jsonResponse({'uv_index': 6.0});
      });

      await UVDataService.fetchUVData();
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
  });

  group('resetUrlPreference', () {
    test('deve voltar a tentar mDNS primeiro após reset', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        if (url.host == 'sunsense.local') {
          throw http.ClientException('DNS failed');
        }
        return jsonResponse({'uv_index': 3.0});
      });
      await UVDataService.fetchUVData();

      UVDataService.resetUrlPreference();

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
